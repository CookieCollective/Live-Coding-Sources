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
#define PI 3.1415926535

float sph(vec3 p, float r) {
  return length(p)-r;
}

float cyl(vec2 p, float r) {
  return length(p)-r;
}

float rnd(float t) {

  return fract(sin(t*425.232)*7423.235);
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1,fract(g)),10) ); 
}

vec3 tunnel(vec3 p) {
  float t = p.z * 0.3 + curve(p.z, 2.9) + curve(p.z + 74, 0.9) * 0.2;
  p.x += sin(t) * 0.3 + (curve(p.z+42,1)-0.5)*0.5;
  p.y += sin(t*1.7 + 23)*0.4;
  p.xy *= rot(p.z*0.1+curve(time, 0.8)*10.1);
  return p;
}

float map(vec3 p) {

  p = tunnel(p);

  vec3 rp = vec3(atan(p.x,-p.y)*PI, length(p.xy), p.z);

  float j = 2.1 + curve(p.z, 2.9)*2;
  float t = texture(texNoise, rp.xz*vec2(0.2,1)*0.4).x;
  float a = -cyl(p.xy,j);
  
  float c = t + 1-cyl(p.xy, 0.9); 

  return min(a, min(c, -p.y+1.4 +t*0.3));
}

vec3 norm(vec3 p) {
  float base=map(p);
  vec2 off=vec2(0.01,0);
  return normalize(vec3( base-map(p-off.xyy), base-map(p-off.yxy), base-map(p-off.yyx) ));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0,0,-3);
  vec3 rd = normalize(vec3(-uv, 1));

  ro.z += time * 4;
  ro = tunnel(ro);

  vec3 p = ro;
  float dd=0;
  float at = 0.0;
  for(int i=0; i<100; ++i) {
    float d = map(p);
    if(d<0.001) {
      break;
    }
    p+=rd*d*0.5;
    dd+=d * 0.5;
    at += exp(-d);
  }

  vec3 n = norm(p);
  vec3 l = normalize(vec3(-1));
  vec3 h = normalize(l-rd);
  float lum = max(0, dot(l,n));

  vec3 col = vec3(0);
  col += vec3(0.8,0.7,0.2) * lum;
  col += vec3(0.8,0.7,1.0) * 0.3 * lum * pow(max(0, dot(n,h)), 10);
  col += vec3(0.2,0.3,0.7) * 0.02 * at;

  col += vec3(1,0.5,0.3) * 0.1 * exp(dd*0.1) * (1 + curve(time+7,0.2)) * 1;

  float t1 = time + curve(time+2,.9) - length(uv) ;
  col.xy *= rot(t1);
  col.yz *= rot(t1*1.2);

  col = abs(col);

  col *= 5/dd;

  

  out_color = vec4(col, 1);
}