#iChannel0 "file://sand-clock-uv.glsl"

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec2 map(vec2 value, vec2 inMin, vec2 inMax, vec2 outMin, vec2 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec3 map(vec3 value, vec3 inMin, vec3 inMax, vec3 outMin, vec3 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec3 map(vec3 value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}


float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float n2(vec3 p) {
  return noise(p + vec3(noise(p), 0., 0.) * 100.);
}

float heightAtPixel(vec2 uv) {
  vec3 prevRgb = texture2D(iChannel0, uv).rgb;
  float height = clamp(prevRgb.b, 0., 1.);
  float heightRandomOffset = n2(vec3(uv.x, uv.y, 0.) * 10000.);
  height += 0.01 * heightRandomOffset;
  return height;
}

float castShadowRay(vec2 uv, float height, vec3 lightDirection) {
  if (height >= 1.) {
    return 1.; // already above
  }
  float stepSize = 0.001;
  lightDirection.z *= 4.;
  vec3 currentLocation = vec3(uv.x, uv.y, height);
  currentLocation += lightDirection * stepSize;

  float count = 0.;
  while (count < 100. && currentLocation.z < 1.) {
    float currentLocationHeight = heightAtPixel(currentLocation.xy);
    if (currentLocationHeight > currentLocation.z) {
      // am now in the sand
      // if it's thin sand return smaller shadow amount
      vec3 peekLocation = currentLocation + (lightDirection * stepSize * 2.);
      float peekLocationHeight = heightAtPixel(peekLocation.xy);
      if (peekLocationHeight < peekLocation.z) {
        // the next sample was going to be back in the air
        return 0.5;
      } else {
        return 0.;
      }
    }
    currentLocation += lightDirection * stepSize;
    count += 1.;
  }
  return 1.; // reached the sky
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  float height = heightAtPixel(uv);
  vec3 prevRgb = texture2D(iChannel0, uv).rgb;
  #iUniform vec3 lightDirectionBase = vec3(0.3, 0.3, 1.) in {-1., 1.};
  #iUniform float lightDirectionSway = 0.3 in {0., 1.};
  float time = iTime;

  vec3 sway = vec3(sin(time), cos(time), 0.) * lightDirectionSway;


  vec3 lightDirection = normalize(lightDirectionBase + sway);
  vec2 prevNormal = map(prevRgb.rg, vec2(0.), vec2(1.), vec2(-1.), vec2(1.));

  float prevNormalZ = (1. - length(vec2(prevNormal.r, prevNormal.g))); // + heightRandomOffset * 0.03;
  vec3 prevNormal3 = normalize(vec3(prevNormal.r, prevNormal.g, prevNormalZ));
  float lightFacing = clamp(dot(prevNormal3, lightDirection), 0., 1.);
  float n = n2(vec3(uv.x * 1000., uv.y * 1000., 0.));
  lightFacing += n * 0.3;
  
  vec3 baseColor = vec3(0.8, 0.7, 0.5);

  float isInLight = castShadowRay(uv, height, lightDirection);

  vec3 specular = pow(vec3(lightFacing), vec3(3.));
  float specularIntensity = isInLight * 0.1;

  float occlusion = mix(mix(1., n, 0.1), 1., isInLight); //map(lightFacing, 0., 1., 0.5, 1.);
  vec3 resultCol = pow(baseColor, vec3((1. - lightFacing) + 1.5)) * occlusion + specular * specularIntensity;
  fragColor = vec4(resultCol, 1.0);
}
