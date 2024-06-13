#iChannel0 "file://images/watch.jpg"
#iChannel1 "file://images/watch_generated.jpg"

float remap(
  float inLow,
  float inHigh,
  float outLow,
  float outHigh,
  float v
) {
  float inRange = inHigh - inLow;
  float outRange = outHigh - outLow;
  float progress = (v - inLow) / inRange;
  return outLow + (progress * outRange);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #iUniform float top = 0.38 in {0., 1.};
    #iUniform float bottom = 0.88 in {0., 1.};
    #iUniform float left = 0.12 in {0., 1.};
    #iUniform float right = 0.63 in {0., 1.};

    vec2 uv = fragCoord/iResolution.xy;
    vec2 uv_two = fragCoord/iResolution.xy;

    uv.y = remap(top, bottom, 0., 1., uv.y);
    uv.x = remap(left, right, 0., 1., uv.x);

    vec4 img = texture2D(iChannel0, uv);
    vec4 img_two = texture2D(iChannel1, uv_two);
    
    vec4 diff = ((img_two - img) + 0.5) / 2.;

    fragColor = diff;
}