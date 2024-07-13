#iChannel0 "file://images/test-image-2.png"

const bool FAST_SRGB = true;

const int COLORSPACE_sRGB = 0;
const int COLORSPACE_linearsRGB = 1;
const int COLORSPACE_oklab = 2;
const int COLORSPACE_XYZ = 3;
const int COLORSPACE_DisplayP3 = 4;
const int COLORSPACE_REC2020 = 5;

// uniform int texture0ColorSpace;

const int texture0ColorSpace = COLORSPACE_sRGB;

const int destinationColorSpace = COLORSPACE_sRGB;

    // structs can't contain samplers.......?
struct colormanaged_texture {
  sampler2D tex;
  int colorspace;
};



const mat3 rec709_to_xyz =
    mat3(0.4124564, 0.3575761, 0.1804375, 0.2126729, 0.7151522, 0.0721750,
         0.0193339, 0.1191920, 0.9503041);

const mat3 xyz_to_rec709 =
    mat3(3.2404542, -1.5371385, -0.4985314, -0.9692660, 1.8760108, 0.0415560,
         0.0556434, -0.2040259, 1.0572252);

const mat3 xyz_to_lms =
    mat3(0.8951000, 0.2664000, -0.1614000, -0.7502000, 1.7135000, 0.0367000,
         0.0389000, -0.0685000, 1.0296000);

const mat3 lms_to_xyz =
    mat3(0.9869929, -0.1470543, 0.1599627, 0.4323053, 0.5183603, 0.0492912,
         -0.0085287, 0.0400428, 0.9684867);

// this is a derivation of sRGB with a different green chromaticity to aid in
// gamut mapping
const mat3 gamut_mapping_temp_to_xyz =
    mat3(0.526817704016889, 0.24315752197868915, 0.18048070105609348,
         0.2716403786337084, 0.6561673409438544, 0.07219228042243739,
         0.024694579875791645, 0.11383147865532788, 0.950531692228759);

// this is a derivation of sRGB with a different green chromaticity to aid in
// gamut mapping
const mat3 xyz_to_gamut_mapping_temp =
    mat3(2.326494774462831, -0.7959898074189706, -0.3812845920560588,
         -0.9692436362808794, 1.8759675015077197, 0.0415550574071756,
         0.055630575696585034, -0.2039779655023635, 1.056972005665519);

vec3 linearsRGBTosRGB(vec3 x) {
  if (FAST_SRGB) {
    return pow(x, vec3(1.0 / 2.2));
  }
  vec3 xlo = 12.92 * x;
  vec3 xhi = 1.055 * pow(x, vec3(0.4166666666666667)) - 0.055;
  return mix(xlo, xhi, step(vec3(0.0031308), x));
}

vec3 sRGBToLinearsRGB(vec3 x) {
  if (FAST_SRGB) {
    return pow(x, vec3(2.2));
  }
  vec3 xlo = x / 12.92;
  vec3 xhi = pow((x + 0.055) / (1.055), vec3(2.4));
  return mix(xlo, xhi, step(vec3(0.04045), x));
}

vec3 xyzToLinearsRGB(vec3 xyz) { return xyz * xyz_to_rec709; }

vec3 linearsRGBToXyz(vec3 rec) { return rec * rec709_to_xyz; }

// from https://bottosson.github.io/posts/oklab/
vec3 linearsRGBToOklab(vec3 c) {
  float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
  float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
  float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;

  float l_ = pow(l, 1.0 / 3.0);
  float m_ = pow(m, 1.0 / 3.0);
  float s_ = pow(s, 1.0 / 3.0);

  return vec3(0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
              1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
              0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_);
}

vec3 oklabToLinearsRGB(vec3 c) {
  float l_ = c.r + 0.3963377774 * c.g + 0.2158037573 * c.b;
  float m_ = c.r - 0.1055613458 * c.g - 0.0638541728 * c.b;
  float s_ = c.r - 0.0894841775 * c.g - 1.2914855480 * c.b;

  float l = l_ * l_ * l_;
  float m = m_ * m_ * m_;
  float s = s_ * s_ * s_;

  return vec3(+4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
              -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
              -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

vec3 oklabToXyz(vec3 ok) {
  vec3 rec = oklabToLinearsRGB(ok);
  return linearsRGBToXyz(rec);
}

vec3 linearsRGBToLms(vec3 c) { return c * rec709_to_xyz * xyz_to_lms; }

vec3 lmsToLinearsRGB(vec3 c) { return c * lms_to_xyz * xyz_to_rec709; }

vec3 gamutMappingTempToXyz(vec3 c) { return c * gamut_mapping_temp_to_xyz; }

vec3 xyzToGamutMappingTemp(vec3 xyz) { return xyz * xyz_to_gamut_mapping_temp; }


vec4 toXYZ(vec4 c, int fromColorSpace) {
  if (fromColorSpace == COLORSPACE_XYZ) {
    return c;
  }
  switch (fromColorSpace) {
    case COLORSPACE_linearsRGB:
      return vec4(linearsRGBToXyz(c.rgb), c.a);
    case COLORSPACE_sRGB:
      return vec4(linearsRGBToXyz(sRGBToLinearsRGB(c.rgb)), c.a);
    case COLORSPACE_oklab:
      return vec4(oklabToXyz(c.rgb), c.a);
    default:
      return vec4(1., 1., 0., 1.);
  }
}

vec4 fromXYZ(vec4 c, int toColorSpace) {
  if (toColorSpace == COLORSPACE_XYZ) {
    return c;
  }
  switch (toColorSpace) {
    case COLORSPACE_linearsRGB:
      return vec4(xyzToLinearsRGB(c.rgb), c.a);
    case COLORSPACE_sRGB:
      return vec4(linearsRGBTosRGB(xyzToLinearsRGB(c.rgb)), c.a);
    case COLORSPACE_oklab:
      return vec4(linearsRGBToOklab(xyzToLinearsRGB(c.rgb)), c.a);
    default:
      return vec4(1., 1., 0., 1.);
  }
}

vec4 convert(vec4 c, int fromColorSpace, int toColorSpace) {
  // Should we assume consumers are only calling this function when needed?
  // From a DX perspective, probably better not to expect that
  // From a perf perspective, we save 1 function call... I don't think it matters all that much
  if (fromColorSpace == toColorSpace) {
    return c;
  }
  // TODO: Find the most common conversion pairs and special-case them here to save some operations?
  vec4 xyz = toXYZ(c, fromColorSpace);
  if (toColorSpace == COLORSPACE_XYZ) {
    return xyz;
  }
  return fromXYZ(xyz, toColorSpace);
}


vec4 cmSample(colormanaged_texture t, vec2 uv, int colorspace) {
  vec4 c = texture2D(t.tex, uv);
  if (t.colorspace == colorspace) {
    return c;
  }
  return convert(c, t.colorspace, colorspace);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = convert(texture2D(iChannel0, uv), texture0ColorSpace, destinationColorSpace);
}