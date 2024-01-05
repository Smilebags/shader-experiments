#iChannel0 "file://images/test-image-2.png"


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
    vec2 uv = fragCoord/iResolution.xy;
    vec4 img = texture2D(iChannel0, uv);
    if (img.a == 1.) {
      fragColor = vec4(img.rgb, 1.);
      return;
    }
    // #iUniform float compositeDepth = 0.5 in {0.0, 1.0};
    // start exploring randomly until you hit an opaque pixel
    vec2 loc = uv;
    vec4 avg = vec4(0.);
    for (float s = 0.; s < 255.; s += 1.) {
      for (float i = 0.; i < 32.; i += 1.) {
        // float x = random((loc + uv + vec2(iTime, 0.)) * 10.) * 100.;
        float x = random((loc + uv + i + s) * 1.);
        float y = random((loc + uv - i - s) * 16.);
        loc = loc + ((vec2(x, y) - 0.5) * 0.005);
        vec4 newSample = texture2D(iChannel0, loc);
        if (newSample.a == 1.) {
          avg = lerp(avg, vec4(newSample.rgb, 1.), 1. - (s / (s + 1.)));
          break;
          // fragColor = vec4(newSample.rgb, 1.);
          // return;
        }
      }
    }
    
    fragColor = avg;
    // fragColor = vec4(uv.x, uv.y, 0., 1.);
}