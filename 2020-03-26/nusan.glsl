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

float time=fGlobalTime;

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
  return fract(sin(t*247.542)*567.665);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1,fract(t)),10));
}

float d2 = 0.0;
float map(vec3 p) {
  
  for(int i=0; i<5; ++i) {
    float t=time*0.1 + i;
    p.xz *= rot(curve(t,0.3)*10.0);
    p.xy *= rot(curve(t,0.23)*7.0);
    p.yz = abs(p.yz) - vec2(0.3,0.8)*(curve(time, 0.2)*0.8+0.2);
  }
  
  float d = box(p, vec3(1,0.3,2.0));
  d2 = length(p.xz) - 0.3;
  d=min(d,d2-0.3);
  
  
  return abs(d);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  if(fract(time*0.1)>0.5) uv.x=abs(uv.x);
  
  vec2 buv=uv;
  for(int i=0; i<2; ++i) {
    uv *= rot(time*0.1);
    uv.x += abs(sin(time + uv.y)*0.1);
    uv.y += abs(sin(time + uv.x)*0.3);
    float size = 30 + pow(curve(time + i*12, .4+sin(uv.x*0.1+time)*0.1),10.0)*200;
    uv=floor(uv*size)/size;
    uv=abs(uv);
  }
  uv-=0.1;

  vec3 s=vec3(0,0,-15);
  vec3 r=normalize(vec3(-uv, 1));
  
  vec3 col=vec3(0);
  vec3 p=s;
  float dd=0;
  for(int i=0; i<70; ++i) {
    float d=map(p) * 0.7;
    if(d<0.01) {
      d=0.01;
    }
    float d2 = sin(d+curve(time,0.2))*0.1+d;
    float ff=0.02;
    r.xz *= rot(sin(dd*0.3*ff));
    r.yz *= rot(sin(dd*0.1*ff));
    p+=r*d2;
    dd+=d;
    col += vec3(1,0.2,0.6) * 0.05/(abs(d)+1.6);
    col += vec3(0.3,0.8,0.7) * 0.004/(abs(d2)+0.2);
  }
    
  float t3 = time*0.1+curve(time, 0.3);
  col.xz *= rot(t3 + buv.x*0.7);
  col.xy *= rot(t3*1.3 + buv.y*0.6);
  col=abs(col);
  col *= 0.4 + curve(time, 0.1);
  col = smoothstep(0,1,col);
  col = pow(col, vec3(0.4545));
  
  /*
  col *= smoothstep(0.1,0.4,fract(curve(uv.x*10.0 + time*0.1,0.1))*0.5)+0.5;
  col *= smoothstep(0.1,0.4,fract(curve(uv.y*10.0 + time*2.3+10.0,0.1))*0.5)+0.5;
  */
  out_color = vec4(col, 1);
}