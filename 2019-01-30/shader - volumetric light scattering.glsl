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

float sph(vec3 p, float r) {
    return length(p)-r;
}

float box(vec2 p, float s) {
  vec2 ap=abs(p)-s;
  return min(0,max(ap.x,ap.y));
}

float cyl(vec2 p, float r) {
    return length(p)-r;
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float map(vec3 p) {

  float a=abs(sph(p,1.0))-0.2;
 
  float c=10000;
  for(int i=0; i<5; ++i) {
    
    float t1=time+i;
    p.xy *= rot(t1);
    p.yz *= rot(t1*0.7);
    //p.xy=abs(p.xy);
    //p-=0.1+i*0.1;
  
  c=min(c,cyl(p.xz, 0.2+0.7*exp(-fract(time*0.2))));

 } 

  return max(a, -c);
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

float rnd(vec2 t) {
  return fract(dot(sin(t*vec2(745.232,456.278)+t.yx*vec2(423.251,895.655)), vec2(7458.232))); 
}

float rnd(float t) {
  return fract(sin(t*445.789)*8956.555);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1,fract(g)), 10)); 
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv.x += (curve(time, 1.7)-0.5)*0.5;
  uv.y += (curve(time, 1.2)-0.5)*0.3;

  vec3 s=vec3(0,0, -7);
  vec3 r=normalize(vec3(-uv, 0.2+curve(time, 0.7)));

  vec3 p=s;
  float dd=0;
  for(int i=0; i<50; ++i) {
    float d=map(p);
    if(d<0.001) {
      break;
    }
    if(dd>60) break;
    p+=r*d;
    dd+=d;
  }

  vec3 pl=vec3(0);
  vec3 l=normalize(vec3(pl-p));

  int steps=30;
  float maxdist=25;
  float stepsize=maxdist/steps;
  vec3 rd=r*stepsize;
  vec3 np =s + rd * (rnd(uv)+2);
  float at=0;

  float rand = rnd(uv+17.52);
  for(int i=0; i<steps; ++i) {

    float shad=1;
    float st=0;
    int shadstep=20;

    vec3 lightd = (l-np)/shadstep;
    vec3 lightp = np + rand * lightd;
    for(int j=0; j<shadstep; ++j) {
      float shadm = map(lightp);
      if(shadm<0.01) {
        shad=0;
        break;
      }
      lightp += lightd;
    }
  
    float len = length(np-pl);
    at += shad*0.04/(pow(len,1.7));
    if(length(np-s)>dd) break;
    np+=rd;
  }

  vec3 n=norm(p);


  vec3 col = vec3(0);
  col += max(0, dot(n,l));
  col += at * vec3(1,.5,0.7)*2;


  float t2 = time*0.7 + curve(time, 0.9)*2.0;
  col.xy *= rot(t2);
  col.yz *= rot(t2*1.3);
  col.xz *= rot(t2*0.7);

  col = abs(col);
  col *= 10;
  col = 1-exp(-col);
  col = pow(col, vec3(1.5));

  out_color = vec4(col, 1);
}