#iChannel0 "file://images/12.jpg"

// normalised XYZ coords
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

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec2 map(vec2 value, vec2 inMin, vec2 inMax, vec2 outMin, vec2 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec3 map(vec3 value, vec3 inMin, vec3 inMax, vec3 outMin, vec3 outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec3 map(vec3 value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

float max3(vec3 v) {
  return max (max (v.x, v.y), v.z);
}

float min3(vec3 v) {
  return min(min(v.x, v.y), v.z);
}

float average3(vec3 v) {
  return (v.x + v.y + v.z) / 3.0;
}

vec3 lerp(vec3 a, vec3 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  vec2 uvCover = (fragCoord - halfRes) / iMax;
  uvCover += 0.5;

  vec3 rgb = pow(texture2D( iChannel0, uvCover).rgb, vec3(2.2));
  vec3 col = rgb;

  // exposure
  #iUniform float exposure = 0.0 in {0.0, 1.0};
  float exposureCorrection = map(exposure, 0., 1., -1.0, 1.0);
  float exposureMultiplier = pow(2.0, exposureCorrection);
  col *= exposureMultiplier;
  
  // blur

  // highlight protection
  #iUniform float highlightProtection = 0.0 in {0.0, 1.0};
  vec3 highlights = pow(rgb, vec3(1.0));
  float highlightAmount = max3(highlights) * highlightProtection;

  col = lerp(col, rgb, highlightAmount);


  // white balance
  #iUniform float wb = 0.5 in {0.0, 1.0};
  vec3 whiteCol;
  if (wb <= 0.5) {
    whiteCol = lerp(D75, D65, wb * 2.0);
  } else {
    whiteCol = lerp(D65, D50, (wb - 0.5) * 2.0);
  }
  vec3 d65LMS = XYZToLMS(D65);
  vec3 whitePointLMS = XYZToLMS(whiteCol);
  vec3 colLMS = XYZToLMS(REC709ToXYZ(col));
  vec3 lmsWeights = d65LMS / whitePointLMS;
  vec3 adaptedColLMS = colLMS * lmsWeights;
  vec3 adaptedColREC = XYZToREC709(LMSToXYZ(adaptedColLMS));
  col = adaptedColREC;

  // fade
  #iUniform float fadeR = 0.5 in {0.0, 1.0};
  #iUniform float fadeG = 0.5 in {0.0, 1.0};
  #iUniform float fadeB = 0.5 in {0.0, 1.0};
  vec3 imageAverageColour = vec3(fadeR, fadeG, fadeB);
  #iUniform float fade = 0.1 in {0.0, 1.0};
  col = lerp(col, imageAverageColour, fade);
  
  // gamut clip
  #iUniform float showGamutClip = 0.0 in {0.0, 1.0};
  if (showGamutClip > 0.5) {
    if (max3(col) > 1.0) {
      col = vec3(1.0, 0.0, 0.0);
    }
    if (min3(col) < 0.0) {
      col = vec3(0.0, 0.0, 1.0);
    }
  }

  fragColor = vec4(pow(col, vec3(1.0 / 2.2)), 1.0);
}
