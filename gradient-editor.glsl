#iChannel0 "file://images/9.jpg"
#iChannel1 "self"
#iChannel2 "file://images/21.jpg"


// const vec2 resolution = vec2(5760.0, 3840.0);

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

mat2 rotate(float r) {
  return mat2(
    cos(r), -sin(r),
    sin(r), cos(r)
  );
}

vec4 lerp(vec4 a, vec4 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 px = 1. / iResolution.xy;
  
  vec4 p = texture2D(iChannel2, uv);
  vec4 pl = texture2D(iChannel2, uv + vec2(-1., 0.) * px);
  vec4 pr = texture2D(iChannel2, uv + vec2(1., 0.) * px);
  vec4 pt = texture2D(iChannel2, uv + vec2(0., -1.) * px);
  vec4 pb = texture2D(iChannel2, uv + vec2(0., 1.) * px);

  vec4 gx = pr - pl;
  vec4 gy = pb - pt;
  vec4 lx = p - ((pl + pr + pb + pt) / 4.);
  
  #iUniform float gradientContrast = 0.0 in {-2.0, 2.0};
  #iUniform float nudge = 0.0 in {-0.001, 0.001};

  lx *= pow(2., gradientContrast);

  vec4 q = texture2D(iChannel1, uv);
  vec4 ql = texture2D(iChannel1, uv + vec2(-1., 0.) * px);
  vec4 qr = texture2D(iChannel1, uv + vec2(1., 0.) * px);
  vec4 qt = texture2D(iChannel1, uv + vec2(0., -1.) * px);
  vec4 qb = texture2D(iChannel1, uv + vec2(0., 1.) * px);

  vec4 g2x = qr - ql;
  vec4 g2y = qb - qt;
  vec4 l2x = q - ((ql + qr + qt + qb) / 4.);

  // difference of laplacians
  vec4 dl = l2x - lx;
  vec4 estimate = q - dl;
  


  // try to find a new color for p that satisfies lx by finding the difference between modified lx and computed lx
  

  if (iFrame <= 20) {
    fragColor = texture2D(iChannel0, uv);
  } else {
    fragColor = clamp(estimate, vec4(0.), vec4(1.));
    fragColor.rgb += vec3(nudge);
    // fragColor.rgb = p.rgb;
    // fragColor.rgb = ((l2x.rgb) + 1.) / 2.;
    // fragColor = vec4(ab, 0., 1.0);
  }
}