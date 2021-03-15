#define PI 3.1415926538
const float INFINITY = 300.0;
const float EPSILON = 0.005;

const float SKY = 0.0;
const float LINE = 1.0;
const float SPHERE = 3.0;
const float FLOOR = 4.0;

const vec3 SUN_DIRECTION = normalize(vec3(1.0, -0.9, 0.4));

vec3 REC709ToXYZ(vec3 rgb) {
  return mat3(
    0.4124564, 0.2126729, 0.0193339,
    0.3575761, 0.7151522, 0.1191920,
    0.1804375, 0.0721750, 0.9503041
  ) * rgb;
}

vec3 XYZToREC709(vec3 xyz) {
  return mat3(
     3.2404542,-0.9692660, 0.0556434,
    -1.5371385, 1.8760108,-0.2040259,
    -0.4985314, 0.0415560, 1.0572252
  ) * xyz;
}

vec3 XYZToxyY(vec3 xyz) {
  float sum = xyz.x + xyz.y + xyz.z;
  return vec3(
    xyz.x / sum,
    xyz.y / sum,
    xyz.y
  );
}

vec3 xyYToXYZ(vec3 xyz) {
  return vec3(
    (xyz.x * xyz.z )/ xyz.y,
    xyz.z,
    ((1.0 - xyz.x - xyz.y) * xyz.z) / xyz.y
  );
}

vec3 sRGBToREC709(vec3 rgb) {
  return pow(rgb, vec3(2.2));
}

vec3 REC709TosRGB(vec3 rgb) {
  return pow(rgb, vec3(1.0 / 2.2));
}

float smin( float d1, float d2, float k ) {
  float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) - k*h*(1.0-h);
}

float smax( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float lerp(float a, float b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

vec3 lerp(vec3 a, vec3 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

float dist(vec3 p1, vec3 p2) {
  return length(p2 - p1);
}

vec3 tonemap(vec3 x)
{
  vec3 xyY = XYZToxyY(REC709ToXYZ(x));
  float Y = xyY.z;
  float scaledY = Y / (1.0 + Y);
  xyY.z = scaledY;

  vec3 whitexyY = XYZToxyY(REC709ToXYZ(vec3(1.0)));

  float saturationFactor = 1.0 - pow(1.0 / (1.0 + Y), 0.5);
  xyY.x = lerp(xyY.x, whitexyY.x, saturationFactor);
  xyY.y = lerp( xyY.y, whitexyY.y, saturationFactor);
  return XYZToREC709(xyYToXYZ(xyY));
}

float sphere(float r, vec3 p) {
  return length(p) - r;
}

float line(float r, vec3 p) {
  if(p.z < 0.0) {
    return length(p) - r;
  }
  if(p.z < 1.0) {
    return length(vec3(p.x, p.y, 0.0)) - r;
  }
  return length(p - vec3(0.0, 0.0, 1.0)) - r;
}

float box(vec3 b, vec3 p) {
    return length(max(abs(p) - b, 0.0));
}

float plane(float h, vec3 p) {
  return p.z - h;
}


vec3 skyCol(vec3 d) {
  float sunFacing = max(dot(d, SUN_DIRECTION), 0.0);
  if (sunFacing > 0.994) {
    return vec3(1.0, 0.75, 0.5) * 64.0;
  }
  float groundOcclusion = 1.0 - max(d.z * -1.0, 0.0);
  vec3 sky = lerp(vec3(0.8, 1.2, 2.0), vec3(1.3, 1.8, 2.0), d.z * -1.0);
  return (sky + pow(sunFacing, 4.0)) * groundOcclusion;
}

vec3 floorCol(vec3 o) {
  return vec3(0.5) + vec3(sin(o.x * 20.0), sin(o.y * 10.0), sin(o.z * 30.0)) / PI;
}

vec2 sdWorld(vec3 p) {
  float minDist = 10000000.0;
  float col = SKY;

  float lineDist = line(0.2, p - vec3(0.0, 0.0, 0.2));
  float floorDist = box(vec3(1.0, 1.0, 0.0001), p + vec3(0.0, 0.0, 0.5)) - 0.5;
  float sphereDist = sphere(0.4, p - vec3(0.7, 0.4, 0.4));

  if(lineDist < minDist) {
    minDist = lineDist;
    col = LINE;
  }

  if(sphereDist < minDist) {
    minDist = sphereDist;
    col = SPHERE;
  }

  if(floorDist < minDist) {
    minDist = floorDist;
    col = FLOOR;
  }
  return vec2(minDist, col);
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(EPSILON, 0.0);
    return normalize(vec3(
    	sdWorld(p+e.xyy).x - sdWorld(p-e.xyy).x,
      sdWorld(p+e.yxy).x - sdWorld(p-e.yxy).x,
      sdWorld(p+e.yyx).x - sdWorld(p-e.yyx).x
	));
}

vec3 reflect(vec3 ri, vec3 n) {
  return ri - (2.0 * n * dot(ri, n));
}

float softShadow(vec3 o, vec3 d) {
  const int maxIterations = 1 << 5;
  float nearest = 1.0;
  
  float t = 0.2;
  for(int i = 0; i < maxIterations; i++)
  {
    vec3 p = o + d * t;
    float d = sdWorld(p).x;
    float od = d / t;
    
    if(od < nearest) {
      nearest = od;
    }
    if(d <= EPSILON) {
      return 0.0;
    }
    if(d >= INFINITY) {
      break;
    }
    t += min(0.5, max(EPSILON, d));
  }
  return nearest;
}

vec4 trace(vec3 o, vec3 d) {
  int iterations = 0;
  int maxIterations = 1 << 6;
  while (iterations < maxIterations) {
    vec2 result = sdWorld(o);
    float minDist = result.x;
    float col = result.y;
    o += d * minDist;
    if (minDist <= EPSILON) {
      return vec4(o, col);
    }
    iterations += 1;
  }
  return vec4(o, SKY);
}

vec3 shadeCol(vec3 o, vec3 d, float matIndex) {
  if(matIndex == LINE) return vec3(0.05, 0.08, 0.1);
  if(matIndex == SPHERE) return vec3(0.95, 0.3, 0.02);
  if(matIndex == FLOOR) return floorCol(o);
  return skyCol(d);
}

vec3 shadeSimple(vec3 o, vec3 d, float matIndex) {
  if(matIndex == SKY) {
    return skyCol(d);
  }
  vec3 col = shadeCol(o, d, matIndex);

  vec3 n = normal(o);
  float cameraFacing = dot(n, d * -1.0);
  float fresnel = lerp(0.04, 1.0, pow(1.0 - cameraFacing, 4.0));
  vec3 shadeFactor = lerp(vec3(0.1, 0.2, 0.3), vec3(1.0, 1.0, 1.0), softShadow(o, SUN_DIRECTION));
  
  vec3 skyColour = skyCol(reflect(d, n));
  vec3 ref = lerp(col, skyColour, fresnel);
  return ref * shadeFactor;
}

vec3 shade(vec3 o, vec3 d, float matIndex) {
  if(matIndex == SKY) {
    return skyCol(d);
  }
  vec3 n = normal(o);

  float cameraFacing = dot(n, d * -1.0);
  float fresnel = lerp(0.04, 1.0, pow(1.0 - cameraFacing, 4.0));

  vec3 shadeFactor = lerp(vec3(0.1, 0.2, 0.3), vec3(1.0, 1.0, 1.0), softShadow(o, SUN_DIRECTION));
  
  vec3 col = shadeCol(o, d, matIndex);
  vec3 newD = reflect(d, n);
  vec4 reflectedPoint = trace(o + n * EPSILON * 2.0, newD);
  vec3 ref = shadeSimple(reflectedPoint.xyz, newD, reflectedPoint.w);
  return lerp(col * shadeFactor, ref, fresnel);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfRes = iResolution.xy / 2.0;
    float iMax = max(iResolution.x, iResolution.y);
    vec2 uvCover = 2.0 * (fragCoord - halfRes) / iMax;

    #iUniform float motion = 1.0 in {0.0, 1.0};


    vec3 staticO = vec3(
      2.0,
      -0.2,
      1.0
    );
    
    vec3 movingO = vec3(
      2.0 * cos(iTime / PI),
      2.0 * sin(iTime / 2.0),
      1.0
    );

    vec3 o = lerp(staticO, movingO, motion);
    float zoom = 1.0;
    vec3 target = vec3(0.0, 0.0, 0.5);
    vec3 globalUp = vec3(0.0, 0.0, 1.0);
    vec3 facing = normalize(target - o);
    vec3 right = normalize(cross(facing, globalUp));
    vec3 down = normalize(cross(facing, right));
    vec3 rayDirection = normalize(facing + (right * (uvCover.x / zoom)) + (-down * (uvCover.y / zoom)));
    vec4 result = trace(o, rayDirection);
    float matIndex = result.w;
    vec3 col = shade(result.xyz, rayDirection, matIndex);

    #iUniform float ev = 0.0 in {-10.0, 10.0};
    #iUniform float tonemapSwipe = 1.0 in {0.0, 1.0};
    float exposure = pow(2.0, ev);
    vec3 displayColour = uv.x > tonemapSwipe ? col * exposure: tonemap(col * exposure);
    fragColor = vec4(displayColour, 1.0);
}
