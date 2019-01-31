#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime

float sph(vec3 p, float r){
  return length(p)-r;
}

float box(vec3 p, vec3 s) {
  vec3 ap=abs(p)-s;
  return length(max(vec3(0),ap)) + min(0, max(ap.x, max(ap.y,ap.z)));
}


float box(vec2 p, float s) {
  vec2 ap=abs(p)-s;
  return length(max(vec2(0),ap)) + min(0, max(ap.x, ap.y));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
  
}

float cyl(vec2 p, float r) {
  return length(p)-r;

}

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5,0,1);
  return mix(a,b,k) - k*(1-k)*h;

}


float rnd(float t) {
  return fract(sin(t*745.523)*8956.565);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1,fract(g)), 10));
}

float mat = 0;
float map(vec3 p) {

  for(int i=0;i<4; ++i) {
    float t1=time*0.2+i +curve(time, 0.3+i*0.3);
    p-=0.1+i*0.1;
    p.xy *= rot(t1);
    p-=0.2+i*0.1;
    p.yz *= rot(t1*1.2);
    p=abs(p);
    p-=0.3+i*0.1;
  }

  vec3 p2 = p;
  float t2 = time*0.4;
  p2.zx *= rot(-t2);
  p2.xy *= rot(-t2*1.3);

  float b = box(p, vec3(0.5,0.2,0.3));
  float c = box(p2.xz, 0.2);
  float e = cyl(p2.xz, 0.2);
  float f  =smin(b,-c, -0.1);

  mat = e<f?1:0;

  return min(e, f);
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

void cam(inout vec3 p) {
  float t1 = time*0.3 + curve(time, 1.2);
  p.yz  *= rot(t1);
  p.zx  *= rot(t1*0.7);
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 s=vec3(0,0,-15);
  vec3 r=normalize(vec3(-uv, 0.7+curve(time, 0.5)));

  cam(r);
  cam(s);
  vec3 col=vec3(0);

  vec3 p=s;
  float side=sign(map(p));
  float prod=1;
  for(int i=0;i<100;++i) {
    float d=map(p)*side;
    if(d<0.001) {
      float curmat=mat;
      vec3 l = normalize(vec3(-1));
      vec3 n=norm(p)*side;
      if(dot(n,l)<0) l=-l;
      vec3 h=normalize(l-r);
      float f=pow(1-max(0,dot(n,-r)),2);
      vec3 spec = mix(vec3(1), vec3(10,6,2), curmat);
      col += f*10*prod*max(0,dot(n,l)) * spec * (0.3*pow(max(0, dot(n,h)),50) +  0.3*pow(max(0, dot(n,h)),10));
      if(curmat>0.5) break;
      prod *=0.9;
      side = -side;
      d=0.01;
      r=refract(r,n, 1+side*0.05);
    }
    if(d>60) break;
    p+=d*r;
  }

  col = 1- exp(-col*2);
  col = pow(col, vec3(1.2));

  out_color = vec4(col, vec3(1));
}