#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 color; // out_color must be written in order to see anything

#define PI 3.14158
#define TAU PI*2.
#define t fGlobalTime*.3

float sphere (vec3 p, float r) { return length(p)-r; }
float cyl (vec2 p, float r) { return length(p)-r; }

vec3 moda (vec2 p, float count) {
  float an = TAU/count;
  float a = atan(p.y,p.x)+an/2.;
  float c = floor(a/an);
  a = mod(a,an)-an/2.;
  c = mix(c, abs(c), step(count/2., abs(c)));
  return vec3(vec2(cos(a),sin(a))*length(p),c); 
}
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float smin (float a, float b, float r) {
  float h = clamp(.5+.5*(b-a)/r, 0.,1.);
  return mix(b,a,h)-r*h*(1.-h);
}

float map (vec3 p);

vec3 normal (vec3 p){
  float e = 0.01;
  return normalize(vec3(map(p+vec3(e,0,0))-map(p-vec3(e,0,0)),
  map(p+vec3(0,e,0))-map(p-vec3(0,e,0)),
map(p+vec3(0,0,e))-map(p-vec3(0,0,e))));
}

float iso (vec3 p, float r) { return dot(p, normalize(sign(p)))-r; }

float map (vec3 p) {
  p.xy *= rot(t);
  p.yz *= rot(t*.5);
  p.xz *= rot(t*.3);
  p.xz *= rot(p.y*.3+t);

  float cyl2 = cyl(p.xz, .3+.8 * (.5+.5*sin(p.y*1.+t*10.)));
  float a = atan(p.y,p.x);
  float l = length(p.xy);
  float c = 10.;
  //p.x = mod(abs(l*.5-4.)+t*2., c)-c/2.;
  //p.y = cos(a)*10.;

  vec3 p1 = moda(p.xz, 20.);
  float wave1 = sin(t*10.+p.y*0.5+p1.z);
  p1.x -= 2.+(.5+.5*wave1);
  p.xz = p1.xy;
  float celly = 3.;
  vec3 p2 = p1;
  p.y = mod(p.y+t*10.+p1.z,celly)-celly/2.;
  float sph1 = sphere(p, 0.2+.2*(.5+.5*sin(p.y+t*10.)));
  float cyl1 = cyl(p.xz, 0.2*wave1+.02);
  float scene = smin(sph1, cyl1, .3);
  scene = smin(scene, cyl2, .3);
    
  p.y = mod(p.y+t*10.,celly)-celly/2.;
  float iso1 = iso(p,0.2+.2*wave1);
  scene = smin(scene, iso1, .13);
  return scene;
}

void main(void)
{
  vec2 uv = (gl_FragCoord.xy-.5*v2Resolution.xy)/v2Resolution.y;
  vec3 eye = vec3(uv, -5.), ray = (vec3(uv,.5)), pos = eye;
  int ri = 0;
  for (int i = 0; i < 50; ++i) {
    float dist = map(pos);
    if (dist < 0.01) {
      break;
    }
    pos += ray*dist;
    ri = i;
  }
  vec3 n = normal(pos);
  float ratio = float(ri)/50.;
  color = vec4(1.);
  color.rgb = n*.5+.5;
  color.rgb *= 1.- ratio;
}