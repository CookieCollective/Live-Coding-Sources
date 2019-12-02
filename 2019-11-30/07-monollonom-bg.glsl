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
#define time fGlobalTime

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float circle(vec2 uv, float id) {
  return smoothstep(length(uv - 0.5), cos(time * 5 + id) * 0.1 + 0.2,  cos(time * 5 + id) * 0.1 + 0.21);
}
void main(void)
{
  // on connait rien en shader
  // soyez sympa
  // on est deux parce que... 
  
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv.y += sin(time);
  uv += vec2(cos(time * 0.1), 0.0);
  float angle = time * 0.1;
  mat2 autreTruc = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
  
  uv *= autreTruc;
  
  // il est sympa il nous aide
  vec2 truc = floor(uv * 10);
  float id = dot(truc, vec2(1.0, 5.0));
  uv = fract(uv * 10);
  
   // on est chaud
  out_color = vec4(circle(uv, id), circle(uv, id), circle(uv, id) * cos(time) * .5 + .5, 1.0);
  out_color = 1.0 - out_color;
}