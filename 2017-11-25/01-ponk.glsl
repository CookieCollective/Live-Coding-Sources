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

#define STEPS 50.
#define PI 3.14159
#define TAU (2.*PI)
#define sdist(v,s) (length(v)-s)
#define time fGlobalTime
#define repeat(v,s) (mod(v,s)-s/2.)

mat2 rot (float a) {
  float c=cos(a),s=sin(a);
  return mat2(c,-s,s,c);
}


void amod (inout vec2 p, float count) {
  float an = TAU/count;
  float a = atan(p.y,p.x)+an/2.;
  a = mod(a,an)-an/2.;
  p = vec2(cos(a),sin(a))*length(p);
}

float map (vec3 pos) {
  float scene = 1000.;
pos.xz *= rot(length(pos)*.3);
pos.xy *= rot(length(pos)*.2);
    pos.xz *= rot(time);
    pos.xy *= rot(time);
vec3 p = pos;
 
  p.xz *= rot(p.y*.5);
  amod(p.xz, 5.);
  p.x -= 1. + .5 * sin(p.y+time);
  p.y = repeat(p.y+time*2., 1.);
   scene = sdist(p, .1);
  scene = min(scene, max(sdist(p.yz, .01),p.x));
  scene = min(scene, sdist(p.xz, .01));
  p = pos;
  p.y = repeat(p.y - time, 2.);
  float wave = 1. * sin(p.y*5.+time);
  //p.x = repeat(p.x, 5.);
  scene = min(scene, max(sdist(p.xz, 1.), abs(p.y)-.01));
  amod(p.xz, 5.);
p.x -= .5;

  scene = max(scene, -sdist(p.xz, .2));
  p.x -= 1.;
 scene = min(scene, sdist(p.xy, .01));

 scene = min(scene, sdist(p.xz, .02));
  
p = pos;
  amod(p.xz, 32.);
  p.x -= 2.;
p.y = repeat(p.y, .5);
  p.x = repeat(p.x-time, 1.);
  scene = min(scene, sdist(p, .02));
  //scene = min(scene, sdist(p.xz, .01));
  p = pos;
  float pl = length(p)*2.-time*5.;
  float lod = 5.2;
  pl = floor(pl*lod)/lod;
  p.xy *= rot(pl);
  scene = min(scene, max(sdist(p.xz, 3.5), abs(p.y)-.001));
  
  p = pos;
  amod(p.xz, 3.);
  p.x -= 2.;
  p.x = repeat(p.x+ time, .2);
  //scene = min(scene, sdist(p.xz, .001));
return scene;

} 

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

   vec3 eye = vec3(0,0,-6);
  vec3 ray = normalize(vec3(uv, 1.));
  vec3 pos = eye;
  float shade = 0.;
  for (float i =0.; i <= 1.; i += 1./STEPS) {
    float dist = map(pos);
    if (dist < .001) {
      shade = 1.-i;
      break;
}
  dist *= .9;
  pos += dist * ray;
  }
  vec4 color = vec4(1.);
  color *= shade;
  out_color = color;
}