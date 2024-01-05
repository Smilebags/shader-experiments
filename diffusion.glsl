#iChannel0 "file://images/test-image-2.png"
#iChannel1 "self"

vec4 alphaOver(vec4 fg, vec4 bg) {
  return vec4(
    mix(bg.rgb, fg.rgb, fg.a),
    bg.a + fg.a * (1.0 - bg.a)
  );
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float r2(vec2 st) {
  return random(vec2(
    random(st),
    random(st * 2.)
  ));
}

float noise(vec3 p) {
  float a = sin(dot(p, vec3(12.9898, 78.233, 151.7182))) * 43758.5453;
  return fract(a);
}
float ns(vec3 p, float s) {
  return noise(p + s);
}

float lerp(float a, float b, float p) {
  return a + ((b - a) * p);
}

vec4 lerp(vec4 a, vec4 b, float p) {
  return vec4(
    lerp(a.r, b.r, p),
    lerp(a.g, b.g, p),
    lerp(a.b, b.b, p),
    lerp(a.a, b.a, p)
  );
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #iUniform float alphaCutoff = 0.9 in {0.0, 1.};
    #iUniform float travelDistance = 0.005 in {0.0, 0.01};
    #iUniform int jumpIterations = 255 in {0, 500};
    #iUniform int sampleIterations = 32 in {0, 500};
    #iUniform float accumulation = 0.015 in {0.0001, 0.1};
    vec2 uv = fragCoord/iResolution.xy;
    vec4 img = texture2D(iChannel0, uv);
    if (img.a >= alphaCutoff) {
      fragColor = vec4(img.rgb, 1.);
      return;
    }

    vec2 loc = uv;
    vec4 avg = vec4(0.);
    for (float s = 0.; s < float(sampleIterations); s += 1.) {
      for (float i = 0.; i < float(jumpIterations); i += 1.) {
        float x = ns(vec3(loc, i), s + 0.001 * iTime);
        float y = ns(vec3(loc, i), s + 1. + 0.001 * iTime);
        loc = loc + ((vec2(x, y) - 0.5) * travelDistance);
        vec4 newSample = texture2D(iChannel0, loc);
        if (newSample.a >= alphaCutoff) {
          avg = lerp(avg, vec4(newSample.rgb, 1.), 1. - (s / (s + 1.)));
          break;
        }
      }
    }

    vec4 self = texture2D(iChannel1, uv);
    if (avg.a == 0.) {
      fragColor = self;
    }
    fragColor = lerp(self, avg, accumulation);
    if (fragColor.a != 0.) {
      fragColor.rgb /= fragColor.a;
    }
    fragColor.a = 1.;
}