#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float sampleTexture(sampler1D sampler)
{
  float m = 0.0;

  for (int i = 0; i< 8; ++i)
  {
    m = max(m, texelFetch(sampler, i, 0).x);
  }

  return m;
}

#define PI 3.141592

void main(void)
{
  vec2 uv = 2.*vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 1.;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float accBass = sampleTexture(texFFTIntegrated);
float currentBass = sampleTexture(texFFTSmoothed)*.1;

  uv.x += sin(accBass)*.5 + currentBass*.2;
  uv.y += cos(accBass)*.5 - currentBass*.2;

  float angle= (atan(uv.x, uv.y)+PI)/(2.*PI)*16.;

  float rot = accBass*.5;

  uv = mat2(cos(rot), -sin(rot), sin(rot), cos(rot))*uv;

  vec3 d = vec3(mix(sqrt(dot(uv, uv)), max(abs(uv.x), abs(uv.y)), (1.-sin(accBass*2.))*.5));

  d.r -= currentBass*.9;
  d.b += currentBass*.9; 

  vec3 v = d;

  v = v*32-fGlobalTime*4.;

  v = sin(v);

  float anim = (1.-sin(fGlobalTime))*.5;

  v *= smoothstep(.1-anim*.1, .25-anim*.25, angle-floor(angle));
  v *= smoothstep(.9+anim*.1,.75+anim*.25, angle-floor(angle));

  v = smoothstep(.0, .1, max(1.-v*v,0.)); 

  v *= smoothstep(.0, .02, angle-floor(angle));
  v *= smoothstep(1.,.98, angle-floor(angle));

  v *=(1.-exp(-d*.4));

  out_color = vec4(v, 1.);
}