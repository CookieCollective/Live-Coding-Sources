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
mat2 r2d(float a){float sa=sin(a),ca=cos(a);return mat2(ca,sa,-sa,ca);}
float sc(vec3 p){
      vec3 a=abs(p);return min(min(max(a.x,a.y),max(a.y,a.z)),max(a.x,a.z));
}
vec2 amod(vec2 p,float a){a=mod(atan(p.x,p.y),a)-a*.5;return vec2(cos(a),sin(a))*length(p);}
float rand(float a){return fract(sin(a)*32163.52131);}
float map(vec3 p){
/*  vec3 o=p;
  p.xy=p.xy=amod(p.xy,radians(120)*sin(o.z*.1)),p.x+=.2;
  p=mod(p,1)-.5;
  return sc(p)-.01;
  */
  vec3 o=p;
  vec3 w=p;
  w.x=abs(w.x)-3.-rand(floor(w.z*.25));
  w.z=mod(w.z,4.)-2.;
  w.xy*=r2d(o.z*.1);
  w=abs(w);
  float h=0;
  if(p.y<1)
  h=+texture(texNoise,p.xz*.1+texture(texNoise,p.xz*.5+time*.02).g*.1).r+texture(texNoise,p.xz*.02).g*5.;
  return min(min(p.y+h,length(p.xy+vec2(0,-1))-.1-sin(time+p.z*3.)*cos(p.z*.2)*.05),(max(w.x,w.z)-.1)*.5);
  
}
vec2 p;
float render(float o){
  float g=time*2.,a=floor(g)+pow(fract(g),5.);
  vec3 ro=vec3(p*r2d(-length(p))+o+vec2(0,.2),-time*7.-a*5.),rd=normalize(vec3(p*r2d(time*.1),-1)),mp;
  float md;mp=ro;int ri;
  for(int i=0;i<70;i++)if(ri=i,mp+=rd*(md=map(mp)),md<.01)break;
  return float(ri)/70.;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  p=uv;
  
  float a=.02;
  out_color = vec4(vec3(1,0,0)*render(a)+vec3(0,1,1)*render(-a),1);
}