// vec3 drawDot(vec4 fragColor, vec2 uv, vec2 pos, float radius, vec3 col) {
//   if (length(uv - pos) > radius)  {
//     return vec3(0.0, 0.0, 0.0);
//   }
//   // fragColor = vec4(col, 1.0);
//   return col;
// }

float noise(vec3 p) {
  return fract(sin(dot(p, vec3(12.9898, 78.233, 151.7182))) * 43758.5453);
}

vec2 sampleCircle(vec3 seed) {
    float r = pow(1.0 - noise(seed), 0.5);
    float a = noise(seed + vec3(1.6425, 4.32462, 1.34132)) * 3.14159 * 2.0;
    vec2 p = vec2(cos(a), sin(a)) * r;
    return p;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  uv -= 0.5;
  uv *= 2.0;
  fragColor = vec4(uv.x, uv.y, 0.0, 1.0);

  #iUniform int sampleCount = 16 in {1, 1024};

  float circle = uv.x*uv.x + uv.y*uv.y < 1.0 ? 0.0 : 1.0;
  fragColor = vec4(vec3(circle), 1.0);
  for (int i = 0; i < sampleCount; i++) {
    vec2 p = sampleCircle(vec3(uv, i));
    if (length(p - uv) > 0.01) {
      continue;
    }
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
  }

  // vec3 resultRGB = (XYZToREC709((col)));

  // fragColor = vec4(uvCover.x, uvCover.y, 0.0, 1.0);
  // drawDot(fragColor, uvCover, vec2(0.333, 0.333), 0.1, vec3(0.0));
  // fragColor = vec4(tonemap(col), 1.0);
}
