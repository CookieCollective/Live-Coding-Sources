#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define T fGlobalTime

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
float C,S;
#define rot(a) mat2(C=cos(a),S=sin(a),-S,C)
#define h(x) fract(sin(x)*1e4)
const float is3=1./sqrt(3.);
mat2 sk=mat2(2*is3,is3,0.,1.)*10.,unsk=inverse(sk);
struct M{
float d;
float f;
};
float rand(vec2 p){
return h(dot(p,vec2(12,78)));
}
float map(vec3 q){
  float d=10e4;
  for(float f=0.;f<10.;++f){
vec3 p=q;
float ri=mod(f+T,10.),
ro=-ri*0.01+.2;
  p.xy*=rot(T*.3+f);
  p.yz*=rot(T*.5+f+p.z*.2);
  p.xz*=rot(T*.7+f+p.x*.2);
  d=min(d,length(vec2(length(p.xz)-ri,p.y))-ro);
}
  return d;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro=vec3(0.,0.,-5.),
rd=normalize(vec3(uv,1.)),
mp=ro;
float f,dmin=10.,dt=.2;
for(f=0.;f<30.;f++){
  float d=map(mp);
  dmin=min(dmin,d);
  if(d<.01)break;
  mp+=rd*d;
}
float r=(dmin-.01)/(dt-.01);
vec3 c=vec3(max(1.-f/30.,r*(1.-r)*4.));
uv*=rot(T*.1);
vec2 skuv=sk*uv;
skuv.x+=T*2.+sin(T)*2.;
vec2 iuv=floor(skuv),
fuv=fract(skuv);
iuv.y+=step(fuv.x,fuv.y)*10.;
float rr=rand(iuv);
c=mix(c,vec3(1),smoothstep(.8,.9,sin(T+rr*6.28358)));
  out_color = vec4(c,1.);
}
