#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNogozon;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define rand(x) fract(sin(x)*1e4)

float dis(vec2 pos, float f)
{
    return pow(pow(abs(pos.x), f)+pow(abs(pos.y), f),1./f);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv *= 2;
  uv -= 1.;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  float a=fract(atan(uv.y,uv.x)/6.28358) * sin(fGlobalTime);
  vec4 r=rand(fGlobalTime+vec4(0,3,5,8));
  vec3 co = vec3(smoothstep(.7, .8 + .2 * sin(fGlobalTime+mod(fGlobalTime,1.0)), dis(uv, 2.+sin(fGlobalTime))));
  vec3 co2 = vec3(smoothstep(.7, .8 + .2 * sin(1.64*fGlobalTime * a), dis(uv, 2.+sin(fGlobalTime*1.64))));
  vec3 co3 = vec3(smoothstep(.7, .8 + .2 * sin(1.23*fGlobalTime * a * 2.) , dis(uv, 2.+sin(fGlobalTime*1.2))));
  float val = texture2D(texNoise,uv * (sin(fGlobalTime*1.0)+1.0)).x;



  out_color = vec4(co.x,co2.y,co3.z, 1.) * (1.0-length(uv) * 0.5);
}