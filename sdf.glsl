#define PI 3.1415926538
const float INFINITY = 300.0;
const float EPSILON = 0.005;

const float SKY = 0.0;
const float LINE = 1.0;
const float SPHERE = 3.0;
const float FLOOR = 4.0;

const vec3 SUN_DIRECTION = normalize(vec3(1.0, -0.9, 1.4));

vec3 tonemap(vec3 x)
{
    // float a = 2.51;
    // float b = 0.03;
    // float c = 2.43;
    // float d = 0.59;
    // float e = 0.14;
    // return (x*(a*x+b))/(x*(c*x+d)+e);
    return vec3(0.0);
}

float smin( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float smax( float d1, float d2, float k )
{
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
  if (sunFacing > 0.99) {
    return vec3(4.0);
  }
  float groundOcclusion = 1.0 - max(d.z * -1.0, 0.0);
  vec3 sky = lerp(vec3(0.8, 1.2, 2.0), vec3(1.3, 1.8, 2.0), d.z * -1.0);
  return (sky + pow(sunFacing, 4.0)) * groundOcclusion;
}

vec3 floorCol(vec3 o) {
  return vec3(0.5) + vec3(sin(o.x * 20.0), sin(o.y * 10.0), 0.0) / PI;
}

vec2 sdWorld(vec3 p) {
  float minDist = 10000000.0;
  float col = SKY;

  float lineDist = line(0.2, p - vec3(0.0, 0.0, 0.2));
  // float floorDist = plane(0.0, p);
  float floorDist = box(vec3(2.0, 2.0, 1.0), p + vec3(0.0, 0.0, 1.0));
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
  const int maxIterations = 16;
  float nearest = 1.0;
  
  float t = 0.1;
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
  int maxIterations = 64;
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
  if(matIndex == SKY) return skyCol(d);
  if(matIndex == LINE) return vec3(0.2, 0.7, 0.2);
  if(matIndex == SPHERE) return vec3(0.9, 0.2, 0.1);
  if(matIndex == FLOOR) return floorCol(o);
  return vec3(0.0);
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
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfRes = iResolution.xy / 2.0;
    float iMax = max(iResolution.x, iResolution.y);
    vec2 uvCover = 2.0 * (fragCoord - halfRes) / iMax;

    vec3 o = vec3(
      3.0 * cos(iTime / PI),
      3.0 * sin(iTime / 2.0),
      1.0
    );
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
    fragColor = vec4(col, 1.0);
    // fragColor = vec4(tonemap(col), 1.0);
}
