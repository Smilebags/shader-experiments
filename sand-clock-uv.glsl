#iChannel0 "self"



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

vec2 dotPosFn(float time) {
  #iUniform float a = 0.5 in {0., 1.};
  #iUniform float rScale = 0.1 in {0., 1.};
  #iUniform float rMin = 0.2 in {0., 1.};
  #iUniform float rMax = 1.0 in {0., 1.};

  float finalRadius = map(sin(time * a), -1., 1., rMin * rScale, rMax * rScale);
  return vec2(
    cos(time) * (finalRadius * 4.),
    sin(time) * (finalRadius * 4.)
  );
}

vec4 alphaOver(vec4 fg, vec3 bg) {
  return vec4(
    mix(bg.rgb, fg.rgb, fg.a),
    1.
  );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  #iUniform int clear = 0 in {0, 1};
  #iUniform float tScale = 5. in {0., 10.};
  float time = iTime *tScale;
  
  if (clear == 1 || time < 0.1) {
    fragColor = vec4(vec3(0.5, 0.5, 1.0), 1.);
    return;
  }
  vec2 uv = fragCoord/iResolution.xy;
  vec2 uvNew = uv;
  uvNew -= 0.5;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  uvNew = (fragCoord - halfRes) / iMax;


  #iUniform float jitterSize = 400. in {10., 1000.};
  #iUniform float jitterAmount = 80. in {70., 90.};
  vec2 prevSampleOffset = vec2(
    noise(vec3(uv * 400., time)),
    noise(vec3(uv * 400., time + 10.))
  ) - 0.5;
  vec4 prev = texture2D(iChannel0, uv + (prevSampleOffset * pow(2., -100. + jitterAmount)));



  vec2 dotPos = dotPosFn(time);
  vec2 nextDotPos = dotPosFn(time + 0.01);
  vec2 heading = normalize(nextDotPos - dotPos);

  vec2 relativePos = uvNew - dotPos;
  #iUniform float dotSize = 0.03 in {0., 0.1};

  
  #iUniform float regen = 0.5 in {0., 1.};
  float heightRegen = pow(regen, 4.) * 0.001;
  float newHeight = clamp(prev.b + heightRegen, 0., 1.);
  prev.b = newHeight;

  if (prev.b >= 1.0) {
    // reset normals if it's reached max height again
    prev.rgb = vec3(0.5, 0.5, 1.0);
  }

  if (length(relativePos) > dotSize) {
    fragColor = prev;
    return;
  }

  relativePos /= dotSize * 2.;
  float alignment = dot(relativePos, heading);

  float b = 1. - length(relativePos);
  float ballHeight = length(relativePos);


  if (ballHeight > prev.b) {
    fragColor = prev;
    return;
  }

  float d = length(relativePos);
  float alpha = smoothstep(-0.1, 0.25, alignment);
  vec3 normal = normalize(vec3(
      -relativePos.x,
      -relativePos.y,
      // -relativePos.x / d / 0.03,
      // -relativePos.y / d / 0.03,
      // ballHeight
      b
    ));
  vec4 normalRgb = vec4(
    map(normal, -1., 1., 0., 1.),
    alpha
  );
  // normalRgb.r = ballHeight;
  // normalRgb.g = ballHeight;
  float newHeightt = min(ballHeight, prev.b);

  fragColor = alphaOver(normalRgb, prev.rgb);
  fragColor.b = min(prev.b, newHeightt);
    
}
