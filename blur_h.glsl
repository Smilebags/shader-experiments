#iChannel0 "file://images/19.jpg"

// const float imageAspect = 4.0 / 5.0;
const float imageAspect = 2.0 / 3.0;
// const float imageAspect = 3.0 / 2.0;
// const float imageAspect = 1.0;

const float PI = 3.14159265;
const float E = 2.7182818284;

float g(float sd, float d) {
  float power = -((d * d) / 2.0 * sd * sd);
  float denominator = pow(2.0 * PI * sd * sd, 0.5);
  return (1.0 / denominator) * pow(E, power);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // vec2 screenUv = fragCoord/iResolution.xy;
  // vec2 halfRes = screenUv / 2.0;
  // float iMax = max(screenUv.x, screenUv.y);
  // vec2 uvCover = ((screenUv - halfRes) / iMax) * vec2(1.0, imageAspect);
  // uvCover += 0.5;

  float screenAspect = iResolution.x / iResolution.y;
  vec2 screenUv = fragCoord/iResolution.xy;
  vec2 centeredScreenUv = screenUv - 0.5;
  centeredScreenUv *= vec2(1.0, imageAspect / screenAspect);

  centeredScreenUv += 0.5;
  vec2 uvCover = centeredScreenUv;

  vec3 col = pow(texture2D( iChannel0, uvCover).rgb, vec3(2.2));

  // blur
  #iUniform float sdX = 0.0 in {0.5, 10.0};
  vec3 sum = vec3(0.0);
  for(float i=-30.0;i<30.0;i += 1.0)
  {
    vec3 sx = texture2D(iChannel0, uvCover + (vec2(i, 0.0) / 1000.0)).rgb;
    vec3 linear = pow(sx, vec3(2.2));
    float gaussianWeight = g(1.0 / sdX, abs(i));
    sum = sum + (linear * gaussianWeight * 0.5);
  }
  sum /= sdX * sdX;
  sum *= 2.0;
  

  fragColor = vec4(sum, 1.0);
}
