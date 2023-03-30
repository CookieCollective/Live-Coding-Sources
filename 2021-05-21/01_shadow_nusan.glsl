#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texRevision;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float fft(float t) { return texture(texFFTSmoothed, fract(t)*.4).x/texture(texFFTSmoothed, 0.001).x; }
float ffti(float t) { return texture(texFFTIntegrated, fract(t)*.4).x; }

float time=mod(fGlobalTime,300);
float box(vec3 p, vec3 s) { p=abs(p)-s; return max(p.x, max(p.y,p.z)); }
mat2 rot(float a) { float ca=cos(a); float sa=sin(a); return mat2(ca,sa,-sa,ca); }

float rnd(float t) {
  return fract(sin(t*452.512)*352.544);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1,fract(t)), 10));
}

float ca=0;
float caid=0;

int id=0;
vec3 pu=vec3(0);
float map(vec3 p) {
  
  vec3 bp=p;
  
  for(int i=0; i<5; ++i) {
    float t=i*3.7+2.7 + rnd(caid)*8;
    p.yz *= rot(t);
    p.xz *= rot(t*.7);     
    p.xz=abs(p.xz)-0.9 - rnd(caid);
  }
  
  float d = length(p)-1;
  
  float s=1;
  float t2 = time*.3 + curve(time, .5)*7;
  float st = 0.2 + curve(time, .7)*.7;
  vec3 p1=(fract(bp/s+.5)-.5)*s;
  float a1=sin(dot(p1.xy,vec2(.8))+t2)*st;
  float d1 = abs(length(p1.xy)-.2)-.05;
  vec3 p2=(fract((bp+s*.5)/s+.5)-.5)*s;
  float a2=sin(dot(p2.yz,vec2(.2))+t2*.7)*st;
  float d2 = abs(length(p2.yz)-.2)-.05;
  vec3 p3=(fract((bp+vec3(s*.5,0,0))/s+.5)-.5)*s;
  float a3=sin(dot(p1.xz,vec2(.3))+t2*1.3)*st;
  float d3 = abs(length(p3.xz)-.2)-.05;
  
  float dd = max(d1, d - a1);
  float dd2 = max(d2, d - a2);
  float dd3 = max(d3, d - a3);
  id=0;
  if(dd2<dd) {
    id=1;
    dd=dd2;
  }
  if(dd3<dd) {
    id=2;
    dd=dd3;
  }
  
  //pu += vec3(1,.9,.4)*0.1*curve(time,.4)/(0.01+abs(max(length(p1.xy)-.15,d-a1-.5)));
  
  return dd * .8;
}

void cam(inout vec3 p) {
  float t=time*(rnd(caid+.24)-.5) + rnd(caid)*247.514;
  p.yz *= rot(sin(t*.7)*.4-.6);
  p.xz *= rot(t);
}

void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  caid = floor(time/4) + floor(time/5);
  ca = max(fract(time/4), fract(time/5));
  
  uv.y -= curve(time+smoothstep(0.7,1.,ca)*rnd(floor(uv.y*50)), .2)*.05;
  
  
  uv *= 1+curve(time-length(uv),.2)*.2;

  float fov = .5 + rnd(caid+.1);
  
  vec3 s=vec3((rnd(caid+.3)-.5)*20,(rnd(caid+.4)-.5)*10,-10 - rnd(caid+.2)*10);
  vec3 r=normalize(vec3(uv, fov));
  
  cam(s);
  cam(r);
  
  vec3 col=vec3(0);
  
  vec3 p=s;
  float atm=0;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) { break; }
    if(d>100.0) { break; }
    p+=r*d;
    atm += 0.015/(max(1.5,d-10.5));
  }
  
  vec3 diff=vec3(1,.9,.3);
  if(id==1) diff=vec3(.6,.5,1);
  if(id==2) diff=vec3(.3,1,.4);
  
  col += pu*.01;
  
  vec3 l=normalize(vec3(1,3,2));
  
  float sss=0;
  vec3 p2=p;
  vec3 r2=l*.08;
  for(int i=0; i<50; ++i) {
    float d=map(p2);
    sss += d*.01;
    p2+=r2;
  }
  
  float fog=1-clamp(length(p-s)/100.0,0,1);
  
  //col += map(p-r) * fog * diff;
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  vec3 h=normalize(l-r);
  float spec = max(dot(n,h),0);
  float fre=pow(1-abs(dot(n,r)),3);
  
  col += sss * fog * (diff + diff*pow(spec,10) + pow(spec, 50));
  col += sss * fog * diff * fre * 2;
  atm *= (1-fog);
  
  atm += texture(texPreviousFrame, gl_FragCoord.xy / v2Resolution.xy).w*pow(curve(time, .2),.4);
  
  vec2 uv2 = uv;
  for(int i=0; i<10; ++i) {
    float t3=time*.3;
    uv2*=rot(t3);
    atm += 0.007/(0.001+abs(uv2.x)) * pow(1-fog,10) * pow(curve(time+i*2.73,.5),10);
    uv2=abs(uv2);
    uv2-=.3;
  }
  
  vec3 aaa=vec3(vec3(.5,.2,.9)+sin(atm*vec3(10,1,2) + time));
  col += (aaa*.2+.8)*atm*.2;
    
  
  //col += pow(1-fog,3)*.01/(0.01+abs(fract(.5*ffti(floor(abs(uv.x)*30)/30))*2-1-uv.y));
  
  col=smoothstep(0,1,col);
  col=pow(col, vec3(0.4545));
  
	out_color = vec4(col, atm);
}