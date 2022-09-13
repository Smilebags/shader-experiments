#iChannel0 "file://images/29.jpg"

float noise(vec3 p) {
  float a = sin(dot(p, vec3(12.9898, 78.233, 151.7182))) * 43758.5453;
  return fract(a);
}
float ns(vec3 p, float s) {
  return noise(p + s);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  vec2 uvCover = (fragCoord - halfRes) / iMax;
  uvCover += 0.5;

  #iUniform float intensity = 1.0 in {0.0, 1.0};


  vec3 rgb = texture2D(iChannel0, uvCover).ggg;
  float threshold = pow(rgb.g, 1.);
  #iUniform int grainPopulation = 5 in {1, 8};
  float grainsPerPixel = float(2 << grainPopulation);
  float density = 0.;
  float minGrainSize = 4. / grainsPerPixel;
  float maxGrainSize = 8. / grainsPerPixel;
  for (float i = 0.; i < grainsPerPixel; i += 1.) {
    float rand = ns(vec3(uv.x / 1., uv.y / 2., i / 1.), rgb.g);
    if (rand > threshold) {
      float grainSize = mix(minGrainSize, maxGrainSize, ns(vec3(uv.x, uv.y, 0.), rand));
      density += grainSize + minGrainSize;
    }
  }
  #iUniform float exposure = 0.0 in {-3.0, 3.0};
  float exposureMultiplier = pow(2., -exposure);
  density *= exposureMultiplier;
  float logTransmission = clamp(pow(0.5, density), 0., 1.);
  float linTransmission = 1.0 - clamp(pow(density, 2.) / 8., 0.0, 1.0);
  #iUniform float logLinMix = 0.5 in {0.0, 1.0};

  float transmission = mix(logTransmission, linTransmission, logLinMix);
  float col = pow(transmission, 1.0/2.2);
  vec3 result = mix(rgb, vec3(col), intensity);
  fragColor = vec4(result, 1.0);
  // fragColor = vec4(rgb, 1.0);
}
