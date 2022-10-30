#iChannel0 "file://rgb.png"
#iChannel1 "file://depth.png"

float accumulate(vec2 uv, vec2 dir) {
  // accumulate density towards dir
  float density = 0.0;
  float count = 32.0;
  float stepSize = 1.0 / count;
  for(float i=0.0; i < count; i++) {
    density += texture2D(iChannel0, uv + -(dir * i * stepSize)).r;
  }
  return density / count;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;

    vec2 lightSource = vec2(0.5, sin(iTime) / 2.0);
    vec2 lightDir = (lightSource - uv);

    float col = accumulate(uv, lightDir);
    fragColor = vec4(vec3(col), 1.0);
}
