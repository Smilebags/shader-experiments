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

vec3 shade(vec3 col, vec3 p) {
  return p + col;
}
vec3 skyCol(vec3 d) {
  return lerp(vec3(0.2, 0.4, 1.0), vec3(0.7, 1.0, 1.0), d.z * d.z);
}

vec3 trace(vec2 uv) {
  vec3 cameraOffset = vec3(
    0.3 * cos(iTime / 3.0),
    0.0,
    0.1 * sin(iTime)
  );
  vec3 o = vec3(0.0, -4.0, 0.5) + cameraOffset;
  vec3 d = vec3(uv.x, 1.0, uv.y);
  d /= len(d);

  int iterations = 0;
  while (iterations < 256) {
    float minDist = 10000000.0;
    vec3 col = vec3(0.0, 0.0, 0.0);

    float lineDist = line(0.2, o);
    if(lineDist < minDist) {
      minDist = lineDist;
      col = vec3(0.2, 0.7, 0.2);
    }

    float sphereDist = sphere(0.4, o - vec3(0.7, 0.4, 0.4));
    if(sphereDist < minDist) {
      minDist = sphereDist;
      col = vec3(072, 0.3, 0.5);
    }

    float floorDist = floorplane(((sin(o.x * 10.0 + iTime)) * 0.1)- 0.2, o);
    if(floorDist < minDist) {
      minDist = floorDist;
      col = vec3(0.9, 0.9, 0.8);
    }

    if (minDist < 0.0001) {
      return shade(col, o);
    }
    o += d * minDist;
    iterations += 1;
  }
  return skyCol(d);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfRes = iResolution.xy / 2.0;
    float iMax = max(iResolution.x, iResolution.y);
    vec2 uvCover = 2.0 * (fragCoord - halfRes) / iMax;

    // Output to screen
    vec3 col = trace(uvCover);
    fragColor = vec4(col, 1.0);
}
