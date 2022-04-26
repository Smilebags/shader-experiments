#iChannel0 "file://my_depth_images/colour/_17A4819-Edit.jpg"
#iChannel1 "file://depth_images/design/yo.png"
#iChannel2 "file://my_depth_images/depth/_17A4819-Edit_dpt_large_resize512.png"
#iChannel3 "file://my_depth_images/depth/_17A4819-Edit_midas_resize512.png"
#iChannel4 "file://my_depth_images/depth/_17A4819-Edit_225_depth.png"

const int salientDepth = 225;
const float initialSweep = float(salientDepth) / 255.0; // half way between salient depth and background

float luminance(vec3 c) {
  vec3 linear = pow(c, vec3(2.2));
  return dot(linear, vec3(0.2126, 0.7152, 0.0722));
}

vec3 design(vec2 uv, vec3 rgb) {
  #iUniform float translateX = 0.5 in {0.0, 1.0};
  #iUniform float translateY = 0.5 in {0.0, 1.0};
  #iUniform float scaleX = 0.5 in {0.0, 2.0};
  #iUniform float scaleY = 0.5 in {0.0, 10.0};
  vec2 designUv = uv;
  designUv -= vec2(0.5);
  designUv += vec2(translateX, translateY) - vec2(0.5);
  designUv /= vec2(scaleX, scaleY);
  designUv += vec2(0.5);
  designUv = clamp(designUv, vec2(0.0, 0.0), vec2(1.0, 1.0));
  vec2 designTranslate = vec2(translateX, translateY);
  float designAlpha = texture2D(iChannel1, designUv).a;
  #iUniform vec3 designColour = vec3(0.49, 0.164, 0.909);
  return mix(designColour, rgb, 1.0 - designAlpha);
}

float sampleDepthMap(vec2 uv) {
float depth = 0.5;
  #iUniform int depthSelector = 3 in {1, 3};
  if (depthSelector == 1) {
    depth = texture2D(iChannel2, uv).r;
  } else if (depthSelector == 2) {
    depth = texture2D(iChannel3, uv).r;
  } else if (depthSelector == 3) {
    depth = texture2D(iChannel4, uv).r;
  }
  depth = 1.0 - depth;
  return depth;
}

float generateMask(vec2 uv, float sweep) {
  #iUniform int useMaskRefine = 0 in {0, 1};
  #iUniform float maskSharpness = 2.0 in {1.0, 12.0};
  float maskSharp = pow(2.0, maskSharpness);
  if(useMaskRefine == 0) {
    float depth = sampleDepthMap(uv);
    return clamp(((sweep - depth) * maskSharp) + 0.5, 0.0, 1.0);
  }
  vec3 centerPixelRGB = texture2D(iChannel0, uv).rgb;
  float centerPixelLuminance = luminance(centerPixelRGB);
  float bias = 0.0;
  float totalInfluence = 0.0;
  #iUniform int kernelSize = 2 in {1, 12};
  float kernelSizeF = float(kernelSize);
  for (float x = -kernelSizeF; x <= kernelSizeF; x += 1.0) {
    for (float y = -kernelSizeF; y <= kernelSizeF; y += 1.0) {
      vec3 currentPixelRGB = texture2D(iChannel0, uv + (vec2(x, y) / iResolution.xy)).rgb;
      float currentPixelDepth = sampleDepthMap(uv + (vec2(x, y) / iResolution.xy));
      float currentPixelLuminance = luminance(currentPixelRGB);
      float dist = abs(centerPixelLuminance - currentPixelLuminance);
      #iUniform float differenceFalloff = 2.0 in {1.0, 4.0};
      float influence = clamp(pow(1.0 - dist, differenceFalloff), 0.0, 1.0);
      float nudge = sweep - currentPixelDepth;
      bias += nudge * influence;
      totalInfluence += influence;
    }
  }

  bias /= totalInfluence;
  float maskFactor = (bias * maskSharp) + 0.5;
  return clamp(maskFactor, 0.0, 1.0);
}


// float smudgeDepthMap(vec2 uv) {
  // vec3 centerPixelRGB = texture2D( iChannel0, uv).rgb;
  // float totalDepth = 0.0;
  // float totalContribution = 0.0;
  // for (float x = -2.0; x <= 2.0; x += 1.0) {
  //   for (float y = -2.0; y <= 2.0; y += 1.0) {
  //     vec3 currentPixelRGB = texture2D(iChannel0, uv + (vec2(x, y) / iResolution.xy)).rgb;
  //     float currentPixelDepth = sampleDepthMap(uv + (vec2(x, y) / iResolution.xy));
  //     float rgbDistance = length(centerPixelRGB - currentPixelRGB);
  //     float contribution = 1.0 - rgbDistance;
  //     // float contribution = 1.0;
  //     totalDepth += currentPixelDepth * contribution;
  //     totalContribution += contribution;
  //   }
  // }
  // return totalDepth / totalContribution;
// }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;

  vec3 rgb = texture2D(iChannel0, uv).rgb;

  #iUniform float sweep = 0.5 in {0.0, 1.0};
  float distanceFromInitial = 1.0 - initialSweep;
  // sweep at 0.0 is 0.0, at 0.5 is initialSweep, and at 1.0 is 1.0
  float biasedSweep = sweep < 0.5 ? sweep * initialSweep * 2.0 : initialSweep + (distanceFromInitial * (sweep - 0.5) * 2.0);
  float mask = generateMask(uv, biasedSweep);
  // fragColor = vec4(vec3(depth), 1.0);
  vec3 col = rgb;
  col *= mask;
  col += design(uv, rgb) * (1.0 - mask);
  // col = design(uv, rgb);
  
  
  fragColor = vec4(col, 1.0);
}
