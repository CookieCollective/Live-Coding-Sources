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

#define time fGlobalTime

#define PI 3.1415
#define TAU 6.28
#define repeat(p,r) (mod(p,r)-r/2.)

float sbox ( vec3 p, float r) {
  vec3 d = abs(p)-r;
  return max(d.x, max(d.y, d.z));
}

mat2 rot (float a) {
  float c=cos(a), s=sin(a); return mat2(c,s,-s,c);
}

void amod(inout vec2 p, float count) {
  float an = TAU/count;
  float a = atan(p.y,p.x);
  a = mod(a, an)-an/2.;
  p = vec2(cos(a),sin(a))*length(p);
}
  

float map (vec3 pos) {
  float scene = 10.;
  vec3 p = pos;
  p.yz *= rot(time*1.);
  p.yx *= rot(sin(time*.1));
  p.xz *= rot(time *  2. + p.y * .2);
  p = abs(p)-2. + 1.*sin(time*2.);
  amod(p.xz, 10. + 5. * sin(time * 4.));
  p.x -= 1.+.5*sin(time*8.+p.y);
  scene = length(p.xz) - .05 + .02 * sin(time*16.);
  p.y += time * 10.;
  float cy = 16.;
  float iy = floor(p.y/cy);
  vec3 pp = p;
  p.y += time * 4.;
  p.y = repeat(p.y, cy);
  scene = min(scene, length(p)-.2+.1 * sin(time*16.+iy*2.));

  cy = 4.;
  p = pp;
  p.y += time * 4.;
  p.y = repeat(p.y, cy);
  scene = min(scene, sbox(p, .3+.2*sin(time)));
  //scene = min(scene, length(p.yz) - .01);
  
  p = pp;
  cy = 10.;
  p.y += time * 4.;
  p.y = repeat(p.y, cy);
  scene = min(scene, max(-(length(p.xz)-8.), max(length(p.xz)-10., abs(p.y)-2.)));
  //scene = max(scene, -(length(p)-.5));
  return scene;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  //uv *= rot(time);
  vec3 eye = vec3(0,0,-5. +  1. * sin(time*8));
  vec3 ray = normalize(vec3(uv,.5 + .3*cos(time*8.)));
  vec3 pos = eye;
  float shade = 0.;
  const float count = 30.;
  for (float i = count; i > 0.; --i) {
    float dist = map(pos);
    if (dist < .001) {
      shade = i / count;
      break;
    }
    pos += ray * dist;
  }

  vec3 color = vec3(.7)+vec3(.9)*sin(vec3(.2,.1,.3)*time * 40. + shade * 2. + pos.z * .5);

  vec2 p = uv*16.;
  p.y -= sqrt(abs(p.x))*1.5-1.5;
  p.x /= 1.2;
  float invert = step(5., (length(p)-sin(time*10.)*3.));

   color *= shade;
  color = mix(color, 1.-color, invert);

  out_color = vec4(color, 1);
}