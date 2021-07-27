#iChannel0 "file://blur_h.glsl"

const float PI = 3.14159265;
const float E = 2.7182818284;

float g(float sd, float d) {
  float power = -((d * d) / 2.0 * sd * sd);
  float denominator = pow(2.0 * PI * sd * sd, 0.5);
  return (1.0 / denominator) * pow(E, power);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;

  vec3 col = texture2D(iChannel0, uv).rgb;
 
  // blur
  #iUniform float sdY = 0.0 in {0.5, 10.0};
  vec3 sum = vec3(0.0);
  for(float i=-30.0;i<30.0;i += 1.0)
  {
    vec3 linear = texture2D(iChannel0, uv + (vec2(0.0, i) / iResolution.y)).rgb;
    float gaussianWeight = g(1.0 / sdY, abs(i));
    sum = sum + (linear * gaussianWeight * 0.5);
  }
  sum /= sdY * sdY;
  sum *= 2.0;
  

  fragColor = vec4(pow(sum, vec3(1.0 / 2.2)), 1.0);
  // vec3 resultRGB = (XYZToREC709((col)));

  // fragColor = vec4(uvCover.x, uvCover.y, 0.0, 1.0);
  // drawDot(fragColor, uvCover, vec2(0.333, 0.333), 0.1, vec3(0.0));
  // fragColor = vec4(tonemap(col), 1.0);
}
