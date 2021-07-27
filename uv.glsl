#iChannel0 "file://images/29.jpg"
#iChannel1 "file://images/uv.jpg"


const vec3 D50 = vec3(0.96422, 1.00000, 0.82521);
const vec3 D55 = vec3(0.95682, 1.00000, 0.92149);
const vec3 D65 = vec3(0.95047, 1.00000, 1.08883);
const vec3 D75 = vec3(0.94972, 1.00000, 1.22638);
const vec3 E = vec3(1.00000, 1.00000, 1.00000);

vec3 REC709ToXYZ(vec3 rgb) {
  return mat3(
    0.4124564, 0.2126729, 0.0193339,
    0.3575761, 0.7151522, 0.1191920,
    0.1804375, 0.0721750, 0.9503041
  ) * rgb;
}

vec3 XYZToREC709(vec3 xyz) {
  return mat3(
     3.2404542,-0.9692660, 0.0556434,
    -1.5371385, 1.8760108,-0.2040259,
    -0.4985314, 0.0415560, 1.0572252
  ) * xyz;
}

vec3 XYZToLMS(vec3 xyz) {
  return mat3(
    0.8951000, 0.2664000, -0.1614000,
    -0.7502000, 1.7135000, 0.0367000,
    0.0389000, -0.0685000, 1.0296000
  ) * xyz;
}

vec3 LMSToXYZ(vec3 lms) {
  return mat3(
    0.9869929, -0.1470543, 0.1599627,
    0.4323053, 0.5183603, 0.0492912,
    -0.0085287, 0.0400428, 0.9684867
  ) * lms;
}

vec3 adapt(vec3 xyz, vec3 sourceWhiteXYZ, vec3 destinationWhiteXYZ) {
  vec3 sourceLMS = XYZToLMS(sourceWhiteXYZ);
  vec3 destinationLMS = XYZToLMS(destinationWhiteXYZ);
  vec3 differenceLMS = destinationLMS / sourceLMS;
  vec3 colLMS = XYZToLMS(xyz);
  colLMS *= differenceLMS;
  return LMSToXYZ(colLMS);
}

vec3 XYZToxyY(vec3 xyz) {
  float sum = xyz.x + xyz.y + xyz.z;
  return vec3(
    xyz.x / sum,
    xyz.y / sum,
    xyz.y
  );
}

vec3 xyYToXYZ(vec3 xyz) {
  return vec3(
    (xyz.x * xyz.z )/ xyz.y,
    xyz.z,
    ((1.0 - xyz.x - xyz.y) * xyz.z) / xyz.y
  );
}

vec3 sRGBToREC709(vec3 rgb) {
  return pow(rgb, vec3(2.2));
}

vec3 REC709TosRGB(vec3 rgb) {
  return pow(rgb, vec3(1.0 / 2.2));
}

float lerp(float a, float b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

vec3 lerp(vec3 a, vec3 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

vec4 lerp(vec4 a, vec4 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

float dist(vec3 p1, vec3 p2) {
  return length(p2 - p1);
}

vec3 tonemap(vec3 x)
{
  vec3 xyY = XYZToxyY(REC709ToXYZ(x));
  float Y = xyY.z;
  vec3 whitexyY = XYZToxyY(REC709ToXYZ(vec3(1.0)));

  // highlight desaturation
  float saturationFactor = 1.0 - pow(1.0 / (1.0 + Y), 0.5);
  xyY.x = lerp(xyY.x, whitexyY.x, saturationFactor);
  xyY.y = lerp( xyY.y, whitexyY.y, saturationFactor);

  // range compression
  Y = xyY.z;
  float scaledY = (Y / (1.0 + Y));
  xyY.z = scaledY;

  return XYZToREC709(xyYToXYZ(xyY));
}


bool isInGamut(vec3 xyz) {
  return xyz.x > 0.0 && xyz.y > 0.0 && xyz.z > 0.0;
}

vec3 locus(vec2 uv) {
  vec3 xyz = xyYToXYZ(vec3(uv.x, uv.y, 1.0));
  if (!isInGamut(xyz)) {
    return vec3(0.0, 0.0, 0.0);
  }
  return XYZToREC709(xyz);
}

void drawDot(vec4 fragColor, vec2 uv, vec2 pos, float radius, vec3 col) {
  if (length(uv - pos) > radius)  {
    return;
  }
  fragColor = vec4(col, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  vec2 uvCover = (fragCoord - halfRes) / iMax;
  uvCover += 0.5;

  #iUniform float exposure = 0.0 in {-5.0, 5.0};
  #iUniform float blacks = 0.0 in {-1.0, 1.0};

  vec3 mappedUv = texture2D( iChannel1, uvCover).rgb;
  vec3 rgb = texture2D( iChannel0, mappedUv.rg).rgb;
  vec3 col = rgb;
  // vec3 col = adapt(REC709ToXYZ((rgb)), E, D65);
  float exposureMultiplier = pow(2.0, exposure);
  col += blacks;
  col *= exposureMultiplier;
  
  #iUniform float sweep = 0.0 in {0.0, 1.0};
  if (uv.x <= sweep) {
    col = mappedUv;
  }
  #iUniform float sweep2 = 0.0 in {0.0, 1.0};
  if (uv.x <= sweep2) {
    col = texture2D( iChannel0, uvCover).rgb;
  }
  fragColor = vec4(col, 1.0);
  // fragColor = lerp(fragColor, vec4(1.0, 0.0, 0.0, 1.0), mappedUv.b);
  // vec3 resultRGB = (XYZToREC709((col)));

  // fragColor = vec4(uvCover.x, uvCover.y, 0.0, 1.0);
  // drawDot(fragColor, uvCover, vec2(0.333, 0.333), 0.1, vec3(0.0));
  // fragColor = vec4(tonemap(col), 1.0);
}
