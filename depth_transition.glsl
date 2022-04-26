#iChannel0 "file://depth_images/colour/brunch.jpg"
#iChannel1 "file://depth_images/depth_c/brunch.png"
#iChannel2 "file://depth_images/colour/foo.png"
#iChannel3 "file://depth_images/depth_c/foo.png"

float sampleDepthMap(vec2 uv, int index) {
float depth = 0.5;
  if (index == 0) {
    depth = texture2D(iChannel1, uv).r;
  } else {
    depth = texture2D(iChannel3, uv).r;
  }
  depth = 1.0 - depth;
  return depth;
}


// float smudgeDepthMap(vec2 uv) {
  // vec3 centerPixelRGB = texture2D( iChannel0, uv).rgb;
  // float totalDepth = 0.0;
  // float totalContribution = 0.0;
  // for (float x = -2.0; x <= 2.0; x += 1.0) {
  //   for (float y = -2.0; y <= 2.0; y += 1.0) {
  //     vec3 currentPixelRGB = texture2D(iChannel0, uv + (vec2(x, y) / iResolution.xy)).rgb;
  //     float currentPixelDepth = sampleDepthMap(uv + (vec2(x, y) / iResolution.xy));
  //     float rgbDistance = length(centerPixelRGB - currentPixelRGB);
  //     float contribution = 1.0 - rgbDistance;
  //     // float contribution = 1.0;
  //     totalDepth += currentPixelDepth * contribution;
  //     totalContribution += contribution;
  //   }
  // }
  // return totalDepth / totalContribution;
// }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord/iResolution.xy;

  // 0.0
  // A        0       1
  //          [-------]
  //                   [-------]
  // B

  // 0.5
  // A        0       1
  //          [-------]
  //          [-------]
  // B
  // 0.5
  // A        0       1
  //          [-------]
  // [-------]
  // B

  vec3 rgbOne = texture2D(iChannel0, uv).rgb;
  float depthOne = sampleDepthMap(uv, 0);
  // fragColor = vec4(vec3(depthOne), 1.0);
  vec3 rgbTwo = texture2D(iChannel2, uv).rgb;
  float depthTwo = sampleDepthMap(uv, 1);

  #iUniform float sweep = 0.5 in {0.0, 1.0};
  depthTwo += 1.0;
  depthTwo -= sweep * 2.0;


  #iUniform float sharpness = 10.0 in {0.0, 100.0};
  float mask = clamp(2.0 * sharpness * (depthTwo - depthOne) + 0.5, 0.0, 1.0);
  // float mask = 0.5;
  vec3 col = mix(rgbTwo, rgbOne, mask);
  
  fragColor = vec4(col, 1.0);
}
