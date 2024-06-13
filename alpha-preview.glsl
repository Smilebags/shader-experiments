// #iChannel0 "file://images/dog-photo.png"
#iChannel0 "file://images/teddyBear.png"
// #iChannel0 "file://images/ob27.png"


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 img = texture2D(iChannel0, vec2(0.1, 0.) + 0.5 * fragCoord/iResolution.xy);
    img.a = 1.0;
    // img.rgb *= img.a;
    fragColor = img;
}