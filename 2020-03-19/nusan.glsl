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

float time = fGlobalTime;

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

float rnd(float t) {
  
  return fract(sin(t*421.522)*742.512);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1,fract(t)),10));
}

vec3 fractal(vec3 p, float t1) {
  
  p.xz *= rot(sin(p.y*0.2+time)*0.5);
  p.yz *= rot(sin(p.x*0.3+time*1.3)*1.5);
    
  for(int i=0; i<7; ++i){
    float t=i + t1*0.1 + curve(t1,0.4)*0.5 + p.x*(0.1+sin(curve(t1,0.2)+t1*0.3)*0.2);
    p.xz *= rot(t);
    p.xy *= rot(t*0.7);
    p.xz = abs(p.xz) - vec2(3,3)*(0.2+i*0.1)*0.7;
  }
  
  return p;
}

float at1=0;
float at2=0;
float map(vec3 p) {

  
  vec3 p2 = fractal(p+vec3(0,0,0), 12.7+time);
  vec3 p3 = fractal(p+vec3(0,2,0), 15.7+time*0.7);
  
  float d=box(p2, vec3(3,2,0.1));
  float d2=box(p3, vec3(3,2,0.1));
  
  
  d=min(d, max(-p.y,length(p.xz)-0.2));
  
  at1 = d;
  at2 = d2;
  
  d=min(d,d2);
  
  d=max(d,0.1);
  
  
  return d;
}

void cam(inout vec3 p) {
  
  
  float t=time*0.2 + curve(time, 1.7)*3.0;
  p.yz *= rot(sin(t*1.3)*0.3+0.6);
  p.xz *= rot(t);
  
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv.x += (curve(time, 0.7)-0.5)*0.5;

  vec3 s=vec3(0,0,-30);
  float fov = 0.9+curve(time, 0.7);
  vec3 r=normalize(vec3(-uv, fov));
  
  cam(s);
  cam(r);
  
  vec3 col=vec3(0);
  
  vec3 p=s;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) break;
    if(d>200.0) break;
    p+=r*d;
    //col += vec3(0.2,0.4,0.9)*0.01/(0.1+abs(d));
    col += vec3(0.2,0.4,0.9)*0.004/(0.1+abs(at1));
    col += vec3(0.9,0.3,0.2)*0.004/(0.1+abs(at2));
  }
  
  col *= 1.2-length(uv);
  
  
  out_color = vec4(col,1);
}