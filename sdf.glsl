float lerp(float a, float b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}
vec3 lerp(vec3 a, vec3 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

float len(vec3 p) {
  return sqrt((p.x * p.x) + (p.y * p.y) + (p.z * p.z));
}

float dist(vec3 p1, vec3 p2) {
  return len(p2 - p1);
}

float sphere(float r, vec3 p) {
  return len(p) - r;
}

float line(float r, vec3 p) {
  if(p.z < 0.0) {
    return len(p) - r;
  }
  if(p.z < 1.0) {
    return len(vec3(p.x, p.y, 0.0)) - r;
  }
  return len(p - vec3(0.0, 0.0, 1.0)) - r;
}

float floorplane(float h, vec3 p) {
  return p.z - h;
}

const float EPSILON = 0.0001;

const float SKY = 0.0;
const float LINE = 1.0;
const float SPHERE = 3.0;
const float FLOOR = 4.0;

vec3 skyCol(vec3 d) {
  return lerp(vec3(0.2, 0.4, 1.0), vec3(0.7, 1.0, 1.0), d.z);
}


vec2 sdWorld(vec3 p) {
  float minDist = 10000000.0;
  float col = SKY;

  float lineDist = line(0.2, p);
  float floorDist = floorplane(0.0, p);
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
  // Rr = Ri - 2 N (Ri . N)
  // ri = ri * -1.0;
  return ri - (2.0 * n * dot(ri, n));
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
  vec3 sunDirection = vec3(1.0, -0.9, 0.4);
  sunDirection /= len(sunDirection);
  vec3 n = normal(o);
  float ang = dot(n, sunDirection);
  float facingLight = ang > 0.0 ? 1.0 : 0.0;
  ang *= facingLight;
  float specA = pow(ang, 3.0);
  float sharp = max((ang * 4.0) - 3.0, 0.0);
  float specB = pow(sharp, 8.0);

  float cameraFacing = dot(n, d * -1.0);
  float fresnel = pow(1.0 - cameraFacing, 2.0);

  vec4 traceresult = trace(o + (n * EPSILON * 2.0), sunDirection);
  vec3 shadeFactor = traceresult.w == SKY ? vec3(1.0, 1.0, 0.9) : vec3(0.3, 0.4, 0.6);
  
  vec3 col = vec3(0.0);
  if(matIndex == LINE) {
    col = vec3(0.2, 0.7, 0.2);
  }
  if(matIndex == SPHERE) {
    col = vec3(0.72, 0.3, 0.5);
  }
  if(matIndex == FLOOR) {
    col = vec3(0.9, 0.9, 0.9);
  }
  vec3 ref = lerp(col * shadeFactor, skyCol(reflect(d, n)), fresnel);
  return ref;
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
      0.3 * cos(iTime / 3.0),
      0.0,
      0.1 * sin(iTime)
    );
    vec3 o = vec3(0.0, -4.0, 1.0) + cameraOffset;
    float zoom = 1.0;
    vec3 d = vec3(uvCover.x / zoom, 1.0, (uvCover.y / zoom) - 0.2);
    d /= len(d);
    vec4 result = trace(o, d);
    float matIndex = result.w;
    vec3 col = shade(result.xyz, d, matIndex);
    fragColor = vec4(col, 1.0);
}
