float nsin(float x) {
  return (sin(x) + 1.0) / 2.0;
}

float linesPhase(vec2 uv, float scale) {
  return (uv.x - uv.y) * scale;
}

float radialPhase(vec2 uv, float scale) {
  return abs(atan(uv.x, uv.y)) * scale;
}

float lerp(float a, float b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}
vec3 lerp(vec3 a, vec3 b, float mix) {
  return (a * (1.0 - mix)) + (b * mix);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 halfRes = iResolution.xy / 2.0;
    float iMax = max(iResolution.x, iResolution.y);
    vec2 uvCover = (fragCoord - halfRes) / iMax;

    #iUniform float linearScale = 10.0 in {0.0, 100.0};
    #iUniform float radialScale = 50.0 in {0.0, 100.0};
    #iUniform float progressSpeed = 2.0 in {0.0, 10.0};
    #iUniform float smoothSharpProgress = 0.5 in {0.0, 1.0};

    float linearPhaseInput = linesPhase(uvCover, linearScale);
    float radialPhaseInput = radialPhase(uvCover, radialScale);

    float multPhase = linearPhaseInput * radialPhaseInput;
    
    float modMix = mod(iTime, 1.0 / progressSpeed) * progressSpeed;
    float sinMix = nsin(iTime * progressSpeed);
    float mix = lerp(modMix, sinMix, smoothSharpProgress);
    float phaseInput = lerp(linearPhaseInput, radialPhaseInput, mix);
    vec3 sweep = vec3(nsin(phaseInput));
    vec3 lines = vec3(nsin(multPhase - mix));
    vec3 orange = vec3(1.0, 0.5, 0.2);


    vec3 col = lerp(orange, mod(sweep,lines), sweep.x);

    // Output to screen
    fragColor = vec4(col,1.0);
}

