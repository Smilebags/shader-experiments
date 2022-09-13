#iChannel0 "file://compositing_images/design2.png"
#iChannel1 "file://compositing_images/uv.png"
#iChannel2 "file://compositing_images/diffuse.png"
#iChannel3 "file://compositing_images/gloss.png"
#iChannel4 "file://compositing_images/uv2.png"
#iChannel5 "file://compositing_images/uvmask.png"
#iChannel6 "file://compositing_images/designgloss.png"

const bool USE_LINEAR = true;
vec3 sRGBToREC709(vec3 rgb) {
  return pow(rgb, vec3(2.2));
}

vec3 REC709TosRGB(vec3 rgb) {
  return pow(rgb, vec3(1.0 / 2.2));
}

float dist(vec3 p1, vec3 p2) {
  return length(p2 - p1);
}

vec4 linearSample(sampler2D tex, vec2 uv) {
  vec4 res = texture2D(tex, uv);
  if (!USE_LINEAR) {
    return res;
  }
  return vec4(sRGBToREC709(res.rgb), res.a);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{

  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  vec2 uvCover = (fragCoord - halfRes) / iMax;
  uvCover *= vec2(9. / 16., 1.);
  uvCover += 0.5;

  vec2 mappedUvA = texture2D( iChannel1, uvCover).rg;
  vec2 mappedUvB = texture2D( iChannel4, uvCover).rg;
  float mappedUvMask = texture2D( iChannel5, uvCover).r;
  vec2 mappedUv = mappedUvA + (mappedUvB * (1./256.));
  if (mappedUvMask < 0.8) mappedUv = vec2(0, 0);
  vec4 designColA = linearSample( iChannel0, mappedUv.rg);
  vec4 designColB = linearSample( iChannel0, mappedUv.rg + vec2(0.002, 0.));
  vec4 designColC = linearSample( iChannel0, mappedUv.rg + vec2(0., 0.002));
  vec4 designColD = linearSample( iChannel0, mappedUv.rg + vec2(0.002, 0.002));
  vec4 designCol = mix(mix(designColA, designColB, 0.5), mix(designColC, designColD, 0.5), 0.5);
  // designCol = designColA;
  vec4 diffuseCol = linearSample( iChannel2, uvCover);
  vec4 glossCol = mix(
    linearSample( iChannel3, uvCover),
    linearSample( iChannel6, uvCover),
    designCol.a
  );
  vec3 col = diffuseCol.rgb;
  col *= mix(vec3(1.0), designCol.rgb, designCol.a);
  col += glossCol.rgb;
  if (USE_LINEAR) {
    col = REC709TosRGB(col);
  }
  // col = designCol.rgb;
  fragColor = vec4(col, 1.0);
}
