#define PI 3.1415926538
const float INFINITY = 300.0;
const float EPSILON = 0.0001;

const float SKY = 0.0;
const float LINE = 1.0;
const float SPHERE = 3.0;
const float FLOOR = 4.0;

const vec3 SUN_DIRECTION = normalize(vec3(1.0, -0.9, 0.4));

vec3 tonemap(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
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
  vec3 sky = lerp(vec3(0.2, 0.4, 1.0), vec3(0.7, 1.0, 1.0), d.z * -1.0);
  return (sky + pow(sunFacing, 4.0)) * groundOcclusion;
}


vec2 sdWorld(vec3 p) {
  float minDist = 10000000.0;
  float col = SKY;

  float lineDist = line(0.2, p - vec3(0.0, 0.0, 0.2));
  float floorDist = box(vec3(4.0, 4.0, 1.0), p + vec3(0.0, 0.0, 1.0));
  float sphereDist = sphere(0.4, p - vec3(0.7, 0.4, 0.4));

  if(lineDist <= minDist) {
    minDist = lineDist;
    col = LINE;
  }

  if(sphereDist <= minDist) {
    minDist = sphereDist;
    col = SPHERE;
  }

  if(floorDist <= minDist) {
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

float softShadow(vec3 ro, vec3 rd) {
    const int ITERS = 30;

    float nearest = 1.0;
    
    float t = 0.1;
    for(int i = 0; i < ITERS; i++)
    {
        vec3 p = ro + rd * t;
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
  int maxIterations = 128;
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

vec3 shade(vec3 o, vec3 d, float matIndex) {
  if(matIndex == SKY) {
    return skyCol(d);
  }
  vec3 n = normal(o);
  float ang = dot(n, SUN_DIRECTION);
  float facingLight = ang > 0.0 ? 1.0 : 0.0;
  ang *= facingLight;
  float specA = pow(ang, 3.0);
  float sharp = max((ang * 4.0) - 3.0, 0.0);
  float specB = pow(sharp, 8.0);

  float cameraFacing = dot(n, d * -1.0);
  float fresnel = lerp(0.04, 1.0, pow(1.0 - cameraFacing, 2.0));

  vec4 traceresult = trace(o + (n * EPSILON * 2.0), SUN_DIRECTION);
  vec3 shadeFactor = lerp( vec3(0.1, 0.2, 0.3), vec3(1.0, 1.0, 0.9), softShadow(o, SUN_DIRECTION));
  
  vec3 col = vec3(0.0);
  if(matIndex == LINE) {
    col = vec3(0.2, 0.7, 0.2);
  }
  if(matIndex == SPHERE) {
    col = vec3(0.72, 0.3, 0.5);
  }
  if(matIndex == FLOOR) {
    col = vec3(0.2, 0.2, 0.2);
  }
  vec3 skyColour = skyCol(reflect(d, n));
  // return skyColour;
  vec3 ref = lerp(col, skyColour, fresnel);
  return ref * shadeFactor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfRes = iResolution.xy / 2.0;
    float iMax = max(iResolution.x, iResolution.y);
    vec2 uvCover = 2.0 * (fragCoord - halfRes) / iMax;

    // Output to screen
    vec3 cameraOffset = vec3(
      3.0 * cos(iTime / PI),
      3.0 * sin(iTime / 2.0),
      1.0
    );
    vec3 o = cameraOffset;
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
    fragColor = vec4(tonemap(col), 1.0);
}
