#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float random (in vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123); }
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  vec2 loduv = v2Resolution.xy/16.0;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv.y *= -1.0;
  float d = length(uv);
  uv *= 1. + 1. * sin(d*2.+2.);// + uv.x*10.);
  uv *= rot((pow(sin(time*2.-d*2.)*0.5+0.5, 8.))*2.);
  uv += 0.5;
  
  
  //uv = floor(uv*loduv)/loduv;
  vec4 color = texture(cookie, uv);
  color.rgb = mix(vec3(0), vec3(1), color.a);
  uv = 2.*(gl_FragCoord.xy-0.5*v2Resolution.xy)/v2Resolution.y;
  //uv = floor(uv*loduv)/loduv;
  d = length(uv);
  //uv *= rot(sin(d*2.-time)*.5);
  uv.y -= pow(abs(uv.x)*.4,0.1)-.8;
  d = length(uv);
  float tint = d*.7-time*.2;
  //tint += 2.*atan(uv.y,uv.x)/3.14;
  float lod = 5.;
  tint = ceil(tint*lod)/lod;
  float s = step(mod(tint*2., 1.),0.5);
  color.rgb = hsv2rgb(vec3(tint, 0.9, color.r));
  
  out_color = color;
}