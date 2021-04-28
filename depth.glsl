#iChannel0 "file://rgb.png"
#iChannel1 "file://depth.png"

struct fireflyResult {
  vec4 col;
  float depth;
};

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

fireflyResult renderFirefly(vec2 uv,  float seed, float baseDepth) {
  vec3 baseCol = vec3(1.0, 0.5, 0.15);
  #iUniform float useMotion = 1.0 in {0.0, 1.0};

  float rand = random(vec2(seed, 100.0));
  float timeOffset = rand * 10000.0;
  float shiftedTime = (iTime + timeOffset);
  float x = (sin(useMotion * shiftedTime * (3.0 + rand)) / 2.5) + 0.5;
  float y = (sin(useMotion * shiftedTime / (7.0 - rand)) / 8.0) + 0.55;
  float distanceToCenter = length(uv - vec2(x, y));
  float sizeMultiplier = 0.02;
  float a = (1.0 / (1.0 + pow(distanceToCenter / sizeMultiplier, 2.0)));

  #iUniform float fireflyOcclusion = 0.2 in {0.0, 1.0};
  #iUniform float fireflyBrightness = 2.0 in {0.0, 10.0};
  fireflyResult result;
  result.col = vec4(baseCol * fireflyBrightness * a, a * fireflyOcclusion);
  result.depth = baseDepth + (10.0 * (rand - 0.5));
  return result;
}

float convertDepth(float d) {
  return 5.0 / d;
}

vec4 addFirefly(vec4 fragColor, float imageDepth, vec2 uv, float startingDepth, float index) {
  float depthSoftness = 2.0;
  fireflyResult firefly = renderFirefly(uv, index, startingDepth);
  if (firefly.depth - depthSoftness > imageDepth) {
    return fragColor;
  }
  float mixFactor = firefly.depth < imageDepth ? 1.0 : smoothstep(depthSoftness, 0.0, firefly.depth - imageDepth);
  vec3 rgb = (firefly.col.rgb) + (fragColor.rgb * (1.0 - firefly.col.a));
  fragColor = vec4(rgb * mixFactor + (fragColor.rgb * (1.0 - mixFactor)), 1.0);
  return fragColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;

    #iUniform float compositeDepth = 0.5 in {0.0, 1.0};
    float convertedCompositeDepth = convertDepth(1.0 - compositeDepth);
    convertedCompositeDepth += sin(iTime / 1.0);
    vec4 col = texture2D(iChannel0, uv);
    float imageDepth = texture2D(iChannel1, uv).r;
    float depth = convertDepth(imageDepth);
    fragColor = vec4(col.rgb, 1.0);
    for(float i=0.0; i < 10.0; i += 1.0)
    {
      fragColor = addFirefly(fragColor, depth, uv, convertedCompositeDepth, i);
    }
    #iUniform float exposure = 0.0 in {-5.0, 5.0};
    float exposureMultiplier = pow(2.0, exposure);
    fragColor = vec4(fragColor.rgb * exposureMultiplier, fragColor.a);
}
