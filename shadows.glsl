#iChannel0 "file://images/26.jpg"

vec3 sRGBToREC709(vec3 rgb) {
  return pow(rgb, vec3(2.2));
}

vec3 REC709TosRGB(vec3 rgb) {
  return pow(rgb, vec3(1.0 / 2.2));
}

vec4 alphaOver(vec4 fg, vec4 bg) {
  return vec4(
    mix(bg.rgb, fg.rgb, fg.a),
    bg.a + fg.a * (1.0 - bg.a)
  );
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float resMax = max(iResolution.x, iResolution.y);
  float resMin = min(iResolution.x, iResolution.y);
  vec2 uvContain = (fragCoord - halfRes) / resMin;
  // vec2 uvCover = (fragCoord - halfRes) / resMax;
  // uvCover += 0.5;
  // uvContain += 0.5;
  vec2 uvToUse = uvContain;

  #iUniform vec2 shift = 0.0 in {0.0, 1.0};
  #iUniform float blur = 0.0 in {0.0, 1.0};

  vec2 shiftPx = shift * 0.125 * resMax;
  float blurPx = blur * 0.125 * resMax;

  float insetPx = max(shiftPx.x, shiftPx.y) + blurPx;
  float inset = insetPx / resMax;
  uvToUse *= 1.2;

  uvToUse += 0.5;
  float uvDistFromOne = length(max(
    max(uvToUse - 1., -uvToUse),
    0.
  ));
  vec4 bg = vec4(uv.x, uv.y, 0.5, 0.96);
  vec4 imageCol = mix(
    texture2D( iChannel0, uvToUse),
    vec4(0., 0., 0., 0.),
    clamp(uvDistFromOne * 100., 0.0, 1.0)
  );
  vec4 shadowCol = vec4(0.0);
  // vec4 result = alphaOver(alphaOver(imageCol, shadowCol), bg);
  vec4 result = alphaOver(imageCol, bg);
  fragColor = result;
}
