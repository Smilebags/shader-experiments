#define PI 3.14159265359
#iChannel0 "file://images/6.jpg"

float DegreesToRadians(float degrees) 
{
    return degrees * PI / 180.0;
}

float RadiansToDegrees(float radians) 
{
    return radians * (180.0 / PI);
}

//Convert RGB with sRGB/Rec.709 primaries to CIE XYZ
//http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
vec3 RGBToXYZ(vec3 color)
{
    mat3 transform = mat3(
        0.4124564,  0.3575761,  0.1804375,
        0.2126729,  0.7151522,  0.0721750,
        0.0193339,  0.1191920,  0.9503041
    );
    
    return transform * color;
}

//http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_Lab.html
vec3 XYZToLab(vec3 xyz) 
{
    vec3 D65 = vec3(0.9504, 1.0000, 1.0888);
    
    xyz /= D65;
    xyz.x = xyz.x >= 0.008856 ? pow(abs(xyz.x), 1.0 / 3.0) : xyz.x * 7.787 + 16.0 / 116.0;
    xyz.y = xyz.y >= 0.008856 ? pow(abs(xyz.y), 1.0 / 3.0) : xyz.y * 7.787 + 16.0 / 116.0;
    xyz.z = xyz.z >= 0.008856 ? pow(abs(xyz.z), 1.0 / 3.0) : xyz.z * 7.787 + 16.0 / 116.0;

    float l = 116.0 * xyz.y - 16.0;
    float a = 500.0 * (xyz.x - xyz.y);
    float b = 200.0 * (xyz.y - xyz.z);
    
    return vec3(l, a, b);
}

//http://www.brucelindbloom.com/index.html?Eqn_Lab_to_LCH.html
vec3 LabToLch(vec3 lab) 
{
    float c = sqrt(lab.y * lab.y + lab.z * lab.z);
    // float h = atan(lab.z, lab.y);
    float h = atan(lab.y, lab.z);
    
    if(h >= 0.0)
    {
        h = RadiansToDegrees(h);
    }
    else
    {
        h = RadiansToDegrees(h) + 360.0;
    }
    
    return vec3(lab.x, c, h);
}

//https://www.academia.edu/13506981/Predicting_the_lightness_of_chromatic_object_colors_using_CIELAB
float CalculateFairchildPirrottaLightness(vec3 lch)
{
    float f1 = 0.116 * abs(sin(DegreesToRadians((lch.z - 90.0) / 2.0))) + 0.085; //HK magnitude
    float f2 = max(0.0, 2.5 - 0.025 * lch.x); //lightness ratio adjustment
    
    return lch.x + f2 * f1 * lch.y;
}

float GetLightness(vec3 color)
{
    vec3 xyz = RGBToXYZ(color);
    vec3 lab = XYZToLab(xyz);
    vec3 lch = LabToLch(lab);
    
    return CalculateFairchildPirrottaLightness(lch) / 100.0;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;
  vec2 halfRes = iResolution.xy / 2.0;
  float iMax = max(iResolution.x, iResolution.y);
  vec2 uvCover = (fragCoord - halfRes) / iMax;
  uvCover += 0.5;

  vec3 rgb = texture2D( iChannel0, uvCover).rgb;
  rgb = pow(rgb, vec3(2.2));
  #iUniform float swipe = 0.0 in {0.0, 1.0};
  #iUniform float bwBrightness = 0.0 in {0.0, 1.0};
  if (uv.x >= swipe) {
    fragColor = vec4(vec3(GetLightness(rgb)) * bwBrightness, 1.0);
  } else {
    fragColor = vec4(rgb, 1.0);
  }
  fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));

}