#iChannel0 "file://images/wallpaper.jpg"

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

mat2 rotate(float r) {
  return mat2(
    cos(r), -sin(r),
    sin(r), cos(r)
  );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 st = uv;
  st -= 0.5;
  st += vec2(
    sin(iTime),
    cos(iTime)
  ) * 0.4;
  st *= rotate(iTime);
  float c = 1. / pow(length(st) * 1., 2.);
  float l = map(sin(st.x * 20.) * c, -1., 1., -1., 1.);
  st = vec2(l, 0.);
  st *= rotate(iTime);
  vec2 ab = vec2(dFdx(st.x), dFdy(st.y));
  vec4 t = texture2D(iChannel0, uv + .01 * ab);
  
  fragColor = t; //
  // fragColor = vec4(ab, 0., 1.0);
}