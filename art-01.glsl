#iChannel0 "file://images/IMG_6873.jpg"
#iChannel1 "file://images/watch_generated.jpg"

const float PI = 3.14159265;

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = iResolution.x/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

float remap(
  float inLow,
  float inHigh,
  float outLow,
  float outHigh,
  float v
) {
  float inRange = inHigh - inLow;
  float outRange = outHigh - outLow;
  float progress = (v - inLow) / inRange;
  return outLow + (progress * outRange);
}

float atan2(in vec2 p)
{
    float x = p.x;
    float y = p.y;
    return atan(y,x);
}

vec4 imgB(vec2 uv) {
  float a = mod(uv.x + uv.y, 1.);
  if (a <= 0.25) {
    return vec4(a, 0.5, 0.75 - uv.y, 1.);
  }
  if (a <= 0.5) {
    return vec4(a, 0.75, uv.y, 1.);
  }
  if (a <= 0.75) {
    return vec4(0.75, a, 0.5, 1.);
  }
  return vec4(vec3(0.), 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #iUniform float blobZoomOffset = 5. in {0., 10.};
    #iUniform float blobZoomSpeed = 10. in {0., 100.};
    #iUniform float blobZoomMagnitude = 10. in {0., 100.};
    #iUniform float spikeCountOffset = 5. in {0., 10.};
    #iUniform float spikeCountSpeed = 10. in {0., 100.};
    #iUniform float spikeCountMagnitude = 10. in {0., 100.};
    #iUniform float radialPhaseOffset = 5. in {0., 10.};
    #iUniform float radialPhaseSpeed = 10. in {0., 100.};
    #iUniform float radialPhaseMagnitude = 10. in {0., 100.};
    #iUniform float radialBiasOffset = 5. in {0., 10.};
    #iUniform float radialBiasSpeed = 10. in {0., 100.};
    #iUniform float radialBiasMagnitude = 10. in {0., 100.};
    float blobZoom = blobZoomOffset + pNoise(vec2(iTime * blobZoomSpeed, 0.), 2) * blobZoomMagnitude;
    float spikeCount = round(spikeCountOffset + pNoise(vec2(iTime * spikeCountSpeed, 2.), 2) * spikeCountMagnitude);
    float radialPhase = radialPhaseOffset + pNoise(vec2(iTime * radialPhaseSpeed, 4.), 2) * radialPhaseMagnitude;
    float radialBias = radialBiasOffset + pNoise(vec2(iTime * radialBiasSpeed, 6.), 3) * radialBiasMagnitude;

    vec2 uv = fragCoord/iResolution.xy;
    uv -= 0.5;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    uv += 0.5;

    
    vec2 a = uv - 0.5;
    float d = length(a);
    float angl = atan2(a);


    float u = d * (blobZoom + sin(spikeCount * angl));
    float v = (radialPhase * cos(radialBias * d));
    
    vec4 img = imgB(vec2(
      u,
      v
      ));
    // vec4 img = texture2D(iChannel0, vec2(
    //   remap(0., 1., 0., 1., x),
    //   remap(0., 1., 0., 1., y)
    //   ));

    fragColor = vec4(vec3(0.), 1.);
    fragColor.x = u;
    fragColor.y = v;
    fragColor = img;
}