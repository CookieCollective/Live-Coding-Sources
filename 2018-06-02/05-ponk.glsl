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

#define smoo(p,r) smoothstep(r,r*1.01,p)
#define time fGlobalTime
#define repeat(p,r) (mod(p,r)-r/2.)

void amod (inout vec2 p, float c) {
  float an = (3.14159*2.)/c;
  float a = atan(p.y,p.x)+an/2.;
  a = mod(a, an)-an/2.;
  p = vec2(cos(a),sin(a)) * length(p);
 }

mat2 rot (float a){
  float c = cos(a), s = sin(a);
  return mat2(c,-s,s,c);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
vec2 ppp = uv;
vec2 uu = uv;
  float wave1 = smoothstep(-1.,.5,sin(time));
  float wave2 = smoothstep(-1.,.1,sin(time*2.));
  float wave3 = smoothstep(-1.,.0,sin(time/2.));
  uv = mix(uv, vec2(atan(uv.y,uv.x), length(uv)), wave3);
  uv.x = mix(uv.x, abs(uv.x), wave1);
  uv.y = mix(uv.y, abs(uv.y), wave2);
  float t = length(uv) * 20. - time;
  vec3 color = vec3(.9)+vec3(.1)*cos(vec3(.1,.2,.3)*t);
  float d = length(uv);
vec2 p = uv;
p *= rot(time+d + sin(d*10.-time)*.1);
amod(p, 8.);
p.x -= .5;
p.x = repeat(p.x - time * .5, .2);
vec2 pp = p;
p *= rot(time);
float scale = 1. +  .1 * sin(time * 16.);
p *= scale;
  p.y += .05;
  p.x /= 1.5;
  p.y -= sqrt(abs(p.x)) * .25;
  float shape = smoo(length(p), .01+.1 * d);
  //shape *= smoo(abs(sin(pp.x*10.)), .02);
  shape = clamp(shape, 0.,1.);

  ppp.y += .05;
  ppp.x /= 1.5;
  ppp.y -= sqrt(abs(ppp.x)) * .45;
  shape = mix(1.-shape, shape, smoo(length(ppp), .2 + .1*sin(time*4.)));
color = mix(vec3(1,0,0), color, shape);
//color = mix(1.-color, color, smoo(length(ppp), .2 + .1*sin(time*4.)));


  float dust = 0.;

  for (float i = 10.; i >= 0.; --i) {
  float rr = i / 10.;
  float a = i * 5. + time;
  float r = i * .05;
  vec2 v = vec2(cos(a),sin(a))*r;
    dust += .002/abs(length(v-uu)-.1*rr+.1*sin(-time*4.+r*10.));
    dust += .001/abs(sin(uu.y*10.+atan(uu.y,uu.x)*10.+time)+.2*sin(-time*4.+r*10.));
}
  color += dust;
  out_color = vec4(color, 1);
}