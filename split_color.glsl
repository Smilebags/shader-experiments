#iChannel0 "file://images/16.jpg"

vec4 toLinear(vec4 c) {
    return pow(c, vec4(vec3(2.2), 1.0));
}

vec4 tosRGB(vec4 c) {
    return pow(c, vec4(vec3(1./2.2), 1.0));
}

vec4 textureLin(sampler2D s, vec2 uv) {
    return toLinear(texture(s, uv));
}

float mapRange(float i, float fromLow, float fromHigh, float toLow, float toHigh) {
    float fromRange = fromHigh - fromLow;
    float toRange = toHigh - toLow;
    return (((i - fromLow) / (fromRange)) * toRange) + toLow;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    vec3 c = toLinear(vec4(vec3(
        mapRange(sin((iTime + 2.5) * 3.0), -1., 1., 0., 1.),
        mapRange(sin((iTime + 7.5 )), -1., 1., 0., 1.),
        mapRange(sin(iTime / 3.0), -1., 1., 0., 1.)
    ), 1.0)).rgb;
    vec3 inv = vec3(1.0) - c;
    if (uv.x < 0.1) {
      fragColor = tosRGB(vec4(uv.y < 0.5 ? c : inv, 1.0));
      return;
    }
    // Time varying pixel color
    vec3 col1 = textureLin(iChannel0, uv).rgb * c;
    vec3 col2 = textureLin(iChannel0, uv + vec2(0.02, 0.)).rgb * inv;
    vec3 col = col1 + col2;

    // Output to screen
    fragColor = tosRGB(vec4(col, 1.0));
}