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
#define STEP 1./100.

float sphere(vec3 p, float r) { return length(p)-r; }

float cylinder(vec2 p, float r) { return length(p)-r; }

float amod (inout vec2 p, float count) {

  float an = 3.14159*2./count;
  float a = atan(p.y,p.x)+an/2.;
  a = mod(a,an)-an/2.;
  p = vec2(cos(a),sin(a))*length(p);
  return 0.;
}

#define time fGlobalTime

mat2 rot (float a) {

  float c=cos(a),s=sin(a);
return mat2(c,-s,s,c);
}

float repeat (float v, float c) { return mod(v,c)-c/2.; }

float smin (float a, float b, float r) {
float h = clamp(.5+.5*(b-a)/r,0.,1.);
return mix(b,a,h)-r*h*(1.-h);
}

void orbit (inout vec3 p) {

p.xz *= rot(fGlobalTime);
p.yz *= rot(fGlobalTime*.7);
p.xy *= rot(fGlobalTime*.4);
p.xy *= rot(length(p)*.2);
p.xz *= rot(length(p)*.5);
p.yz *= rot(length(p)*.3);
}

float rand (vec2 s) { return fract(sin(dot(s, vec2(55.,100.)))*440545.); }

float map (vec3 pos) {
  float scene = 1000.;
vec3 p = pos;
orbit(p);
p.xz *= rot(p.y*.3);
  amod(p.xz, 12.);

  float wave = sin(time+p.y*2.);
  p.x -= 1. + .2*wave;
//p.x = repeat(p.x, 1.);
scene = min(scene, cylinder(p.xz, .1));
p.y = repeat(p.y + time, .2);
  scene = smin(scene, cylinder(p.xy, .02), .1);
  scene = smin(scene, cylinder(p.yz, .02), .1);

p = pos;
orbit(p);
p.xz *= rot(p.y*5.);
amod(p.xz, 5.);
p.x -= .2 + wave * .2;

p.y = repeat(p.y, .5);
  scene = smin(scene, sphere(p, .2 + .1 * wave), .1);
  p = pos;

amod(p.xz, 5.);
orbit(p);
p.x = repeat(p.x, 1.);
p.y = repeat(p.y, .5);
  scene = smin(scene, sphere(p, .2 + .1 * wave), .1);
return scene;
}

vec3 getNormal (vec3 p) {
vec2 e = vec2(.01,.0);
return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),map(p+e.yxy)-map(p-e.yxy),map(p+e.yyx)-map(p-e.yyx)));
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
uv.x *= v2Resolution.x/v2Resolution.y;
   vec3 eye = vec3(0,0,-4);
vec3 ray = normalize(vec3(uv, .2));
vec3 pos = eye;
float shade = 0.;
for (float i =0.; i <= 1.; i += STEP) {
float dist = map(pos);
if (dist < .1) {
  shade += 1./STEP;
}
if (shade >= 1.) break;
dist = max(dist, .001);
dist *= .6 + .1 * rand(uv);
pos += ray * dist;
}
  vec3 color = vec3(1);
vec3 normal = getNormal(pos);
color = normal*.5+.5;
  color *= shade;
  out_color = vec4(color, 1);
}