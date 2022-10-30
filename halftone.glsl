#iChannel0 "file://images/16.jpg"

vec4 toLinear(vec4 c) {
    return pow(c, vec4(vec3(2.2), 1.0));
}

vec4 toLog(vec4 c) {
    return vec4(vec3(log(c.rgb)), c.a);
}

vec4 fromLog(vec4 c) {
    return vec4(vec3(exp(c.rgb)), c.a);
}

vec4 tosRGB(vec4 c) {
    c.rgb = max(c.rgb, vec3(0.));
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

float circle(float r, vec2 uv) {
    return length(uv) - r;
}

vec3 mix3(vec3 a, vec3 b, vec3 c) {
    return vec3(
        mix(a.r, b.r, c.r),
        mix(a.g, b.g, c.g),
        mix(a.b, b.b, c.b)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (uv * 2.) - 1.0;

    // vec3 c = toLinear(vec4(vec3(
    //     mapRange(sin((iTime + 2.5) * 3.0), -1., 1., 0., 1.),
    //     mapRange(sin((iTime + 7.5 )), -1., 1., 0., 1.),
    //     mapRange(sin(iTime / 3.0), -1., 1., 0., 1.)
    // ), 1.0)).rgb;
    // vec3 inv = vec3(1.0) - c;
    // if (uv.x < 0.1) {
    //   fragColor = tosRGB(vec4(uv.y < 0.5 ? c : inv, 1.0));
    //   return;
    // }
    // // Time varying pixel color
    vec3 col1 = textureLin(iChannel0, uv).rgb;
    // vec3 col2 = textureLin(iChannel0, uv + vec2(0.02, 0.)).rgb * inv;
    // vec3 col = col1 + col2;
    #iUniform float intensity = 6.0 in {4.0, 8.5};
    float i2 = pow(2., intensity);

    // float xr = sin(p.x * i2);
    // float yr = sin(p.y * i2);
    // float zr = xr * yr;

    vec2 m = mod(p, vec2(1. / i2)) * i2;
    float ml = m.x * m.y;

    // col1 += 3.0 * zr;
    // col1 += 4.0;

    // vec3 res = vec3(
    //     smoothstep(-5.1, 5.1, col1.r),
    //     smoothstep(-5.1, 5.1, col1.g),
    //     smoothstep(-5.1, 5.1, col1.b)
    // );
    vec3 col = mix3(vec3(0.), vec3(1.0), ((col1 + ml) - 0.5) * 2.);
    // vec3 col = vec3(ml);

    // Output to screen
    fragColor = tosRGB(vec4(col, 1.0));
}