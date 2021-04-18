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

#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
float rand(float x){ return fract(fract(sin(x*234.2342))*234.234);}
float c(float t, float s){
  t/=s;
  return mix(rand(floor(t)), rand(floor(t)), smoothstep(0., 1., pow(fract(t), 20.)));
}
float t= mod(fGlobalTime, 40.);
float tri(vec3 p, vec3 s){
  p.xz=abs(p.xz);
  vec2 a = vec2(0.4);
  return max(max(p.y-s.y, dot(p.xy, a)), p.z);
}
float g1,g2;
float m(vec3 p){
  vec3 p1=p;
  float ii;
  for(float i = 8;i--;){
    p1.xz*=rot(t*.234);
    p1.yz*=rot(t*.23244);
    p1=abs(p1)-40.-i;
    ii+=i;
  }
  float a=tri(p1, vec3(1.))*.15;
  g1+=.5/(.1+a*a);
  vec3 p2 = p;
  p2=abs(p2)-5.;
  p2=(fract(p2/100.+.5)-.5)*100.;
  p2=abs(p2)-.5;
  float cc=max(max(p2.z, p2.x), p2.z);
  a=min(1., cc);
  g2+=.1/(1.+cc*cc);
  vec3 p3=p;
  float tt=c(t*.5, 10.)*2.+t;
  p3.xz*=rot(tt*.7);
  p3.xy*=rot(tt*.5);
  p3=abs(p3)-5.;
  
  float cc2=max(max(p3.x, p3.z), p3.y);
  a=min(a, cc2);
  return a;
}
float ao(vec3 n, vec3 p, float d){
  float o;
  for(float i=8;i--;)
    o+=clamp(m(p+n*d*i*i)/d*i*i, 0., 1.);
  return o;
}

void cam(inout vec3 p){
  p.xz*=rot(t*.17);
}
vec3 nm(vec3 p){const vec2 e = vec2(0.01, 0.); return m(p)-normalize(vec3(m(p-e.xyy), m(p-e.yxy), m(p-e.yyx)));}
void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float fov = 1.+length(uv)*sin(t)*.25;
  vec3 s = vec3(0.001, 0.00001, -55.), r = normalize(vec3(uv, fov));
  cam(s), cam(r);
  vec3 p=s; float d;
  vec3 n=vec3(.25);
  float i;
	for(i=64.; i--;) if(d=m(p),p+=d*r,abs(d) < .001) n*=nm(p);
  n=nm(p);
  n*=ao(n,p,1.)*.24;
  
	out_color = vec4(vec3(g2*vec3(0., 0.234, 0.3435)+g1*vec3(0.234, 0., .134)-(max(length(p-s)/100., 0.)*
  1-dot(n,normalize(vec3(-10., -20., -1e5))*0.00001))), 1.);
}
