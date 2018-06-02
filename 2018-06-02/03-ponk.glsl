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

#define sdist(p,r) (length(p)-r)
#define time fGlobalTime
#define repeat(p,r) (mod(p,r)-r/2.)

mat2 rot (float a) {
  float c = cos(a), s = sin(a);
  return mat2(c,-s,s,c);
}

void amod (inout vec2 p, float c) {
  float an = (3.14159*2.)/c;
  float a = atan(p.y,p.x)+an/2.;
  a = mod(a, an)-an/2.;
  p = vec2(cos(a),sin(a))*length(p);
}

float smin ( float a, float b, float t) {
  float h = clamp(.5+.5*(b-a)/t,0.,1.);
  return mix(b,a,h)-t*h*(1.-h);
}

float map (vec3 pos) {
  float scene = 10.;
  vec3 p = pos;
  const float count = 3.;
  for (float i = count; i >= 0.; --i) {
    float r = i / count;
    r = r * r;
    p.xz *= rot(p.y * .4 / r);
    amod(p.xz, 5.);
    p.x -= .5 * r - sin(time * 2. + p.y * 2. + r * 3.14529) * .1 * r;
    vec3 pp = p;
    scene = min(scene, sdist(p.xz, .01));
  }
  p = pos;
  p.xz = vec2(atan(p.x,p.z),length(p.xz));
p.y += sin(atan(p.z,p.x)/3.14159/2.)*.2;
p.y = repeat(p.y+time, .6);
float wave = 1. - .1*sin(time * 2. + pos.y * 4.);
p.z -= wave;
  scene = min(scene, sdist(p.zy, .01));
p = pos;
p.xz *= rot(p.y);
amod(p.xz, 8.);
p.x -= wave;
  scene = smin(scene, sdist(p.xz, .01), .1);
p = pos;
p.xz *= rot(-p.y);
amod(p.xz, 8.);
p.x -= wave;
  scene = smin(scene, sdist(p.xz, .01), .1);
float dd = length(pos);
p.y += atan(pos.z,pos.x) * .5;
  scene = smin(scene, sdist(p.yz, .01 - dd * .03), .1);
p.x -= .5;
p.x = repeat(p.x, .8);
  scene = smin(scene, sdist(p.xy, .02), .2);
  return scene;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0,1,-3);
  eye.xz *= rot(time);
  eye.z += sin(time);
  vec3 target = vec3(0);
  vec3 front = normalize(target - eye);
  vec3 right = normalize(cross(vec3(0,1,0),front));
  vec3 up = normalize(cross(front, right));
  vec3 ray = normalize(front + uv.x * right + uv.y * up);
  vec3 color = vec3(uv,0);
  float shade = 0.;
  vec3 pos = eye;
  const float count = 70.;
  for (float i = count; i >= 0.; --i) {

    float dist = map(pos);
    if (dist < .0001) {
      shade = i / count;
      break;
    }
dist *= .5;
    pos += ray * dist;
  }

  float t = shade * 40. + time;
  color = vec3(.75)+vec3(.25)*cos(vec3(.1,.2,.3)*t);
  color *= shade;

  out_color = vec4(color, 1);
}