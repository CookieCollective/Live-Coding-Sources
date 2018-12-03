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

#define PI 3.1415
#define TAU 6.283
#define repeat(p,r) (mod(p,r)-r/2.)

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

mat2 rot (float a) { 
  float c = cos(a), s = sin(a); return mat2(c,s,-s,c); }

void amod (inout vec2 p, float count) {
  float c = count/TAU;
  float a = atan(p.y, p.x);
  a = mod(a, c)-c/2.;
  p = vec2(cos(a),sin(a))*length(p);
}

float map (vec3 pos) {
  
  float scene = 10.;

  float d = length(pos) * 4.;
  //pos.xz *= rot(d + time);
  //pos.yz *= rot(d + time);
  vec3 p = pos;
  vec3 pp = p;
  
  const float count = 3.;

   
  for (float i = count; i > 0.; --i) {
    
    float r = i / count;
    //amod(p.xz, 5.);
    p = abs(p)-.2*r;
    p.x -= .2 * r;
    p.xz *= rot(time*.4);
    p.yz *= rot(time*.3);
    p.xz *= rot(sin(time*2.)*2.);

    float rr = (.01*r + .005 * sin(time * 12.) * r);
    scene = min(scene, length(p.xz)-rr);
    scene = min(scene, length(p.yz)-rr);

    pp = abs(pp) - (.2 + .1 *sin(time*2.)) * r;
    pp.xz *= rot(time);
    pp.yz *= rot(time);
    //pp.xz *= rot(sin(time*40.)*.1);
    
    scene = min(scene,  length(pp)-.1*r);
  }

  p = pos;

  p.z += time * 2.;
  p = repeat(p, .3);

  scene = min(scene, length(p)-.01);

  return scene;
  
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float a = atan(uv.y, uv.x);
  float d = length(uv);
  uv *= rot(time);

  amod(uv, 10.);

  //uv.x += sin(uv.y*1000.)*.001;

  vec3 eye = vec3(0,0,-1.5);
  vec3 ray = normalize(vec3(uv, .5+.4*sin(time*4.)));
  vec3 pos = eye;
  float shade = 0.;
  const float count = 50.;
  for (float i = count; i > 0.; --i) {
    float dist = map(pos);
    if (dist < .001) {
      shade = i / count;
      break;
    }
    pos += ray * dist * .5;
  }

  float invert = step(sin(length(uv)*2.-time*2.5), .0);

  shade = mix(shade, 1.-shade, invert);

  vec3 color = vec3(.5)+vec3(.5)*sin(vec3(.1,.2,.3)*time*4. + shade * 4.);
  

  out_color = vec4(shade);
}