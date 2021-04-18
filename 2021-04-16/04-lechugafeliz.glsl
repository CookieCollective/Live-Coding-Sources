#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texLogo;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float t=mod(fGlobalTime, 50.);
float rand(float x){ return fract(sin(x*324.234)*234.234); }

#define smin(a, b, k) min(a, b)-pow(max(k-abs(a-b),0.), k)*k*(1.0/6.0);
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
float c(float t, float s){
  t/=s;
  return mix(rand(floor(t)), rand(floor(t+1)), pow(smoothstep(0., 1., fract(t)), 20.));
}
float sb(vec3 p, vec3 s){
  p=abs(p)-s;
  return max(max(p.y, p.x), p.z);
}
float m2(vec3 p){
  vec3 p1=p;
  p1.xy=abs(p1.xy)-10.;
  for(float i= 0; i < 4; i++){
    p1=abs(p1)-20;
    p1.xy*=rot(t);
  }
  
  vec3 p2=p;
  float a=length(p1)-2.;
  for(int i = 0; i < 3; i++){
    p2.xz*=rot(t*.2);
    p2.yx*=rot(t*.345);
    p2=smin(p2,6-p2,vec3(6.));
  }
  float b= sb(p2, vec3(1.));
  
  float d=b;
  float m=mix(a, b, sin(t*2.)*.25-.5);
  return min(d, m);
  
}
float g1,g2;
void orbit(inout vec3 p1){
  const float rr=4.5;
  p1.x+=sin(t)*rr;
  p1.z+=cos(t)*rr;
}
float m(vec3 p){float d=m2(p);
  vec3 p1=p;
  
  
  p1=abs(p1)-5.;
  orbit(p1);
  const float ss= .1;
  float esf=length(p1.yz)-ss;
  g2+=.01/(.1+esf*.5);
  vec3 p2=p.zxy;
  orbit(p2);
  float esf2=length(p2.xy)-ss;
  g1+=.1/(1+esf2*esf2);
  d=smin(d, esf, 0.2);
  d=smin(d, esf2, 0.2);
  return d;
}
void cam(inout vec3 p){p.xz*=rot(t*.5); p.yx*=rot(t*.435);}
void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec3 s=vec3(0.0001, 0.001, -20.), r=normalize(vec3(uv, 1.));
  cam(s), cam(r);
  vec3 p=s;
  float i,d;
  const float MAX=100.;
  
  for(i=MAX;i--;){
    d=m(p);
    if(abs(d) < .0001 || d >MAX) break;
    p+=d*r;
  }
  
  vec3 col=vec3(0.);
  col+=1-i/MAX;
  vec3 c1 = vec3(0.234, 0.345, 0.1);
  vec3 c2 = vec3(0.234, 0.345, 0.1);
  c1.xy*=rot(t);
  col+=g1*c1;
  col+=g2*c2;
	out_color = vec4(col,1.);
}
