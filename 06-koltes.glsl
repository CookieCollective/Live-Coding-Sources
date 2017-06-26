#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
#define t fGlobalTime
float C,S;
#define rot(a) mat2(C=cos(a),S=sin(a),-S,C)
struct M{float d;vec3 c;};
M mmin(M a,M b,float k){
float h=clamp((b.d-a.d)/k*.5+.5,0.,1.);
M m;
m.d=mix(b.d,a.d,h)-k*h*(1.-h);
m.c=mix(b.c,a.c,h);
return m;
}
M map(vec3 p){
p.xz*=rot(t*.3);
p.y+=.2*sin(t*3.);
float a=atan(p.z,p.x);
  M m;
  float d=length(p.xz);
  d=dot(normalize(vec2(.9,-.2)),vec2(d,p.y+2.));
  d=max(d,p.y-.5);
m.d=d;
vec2 st=vec2(a*10.,-a*1.);
st*=(1.-st);
m.c=vec3(.9,.8,0.);
d=length(p.xz)-.8*(smoothstep(.0,.5,p.y)-smoothstep(1.5,2.5,p.y))+.1-.1*sin(a*8.+p.y*15.);
M m2;
m2.d=d;
m2.c=mix(vec3(.9),vec3(.9,.1,.1),step(.5,fract(a/6.2831*8.+p.y*15./6.2831)));
m=mmin(m,m2,.1);
return m;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro=vec3(uv,-5.),rd=normalize(vec3(uv,1.)),mp=ro;
M m;
float f;for(f=0.;f<30.;++f){
m=map(mp);
if(abs(m.d)<.001)break;
mp+=rd*m.d;
}
float a=atan(uv.y+.8,uv.x)/6.2831*40.+t;
  vec3 bg=mix(vec3(.0,.4,.8), vec3(.1,.5,.9),step(.5,fract(a)));
  float mbg=min(1.,length(mp-ro)*.01);
  vec3 c=mix(m.c*(1.-f/30.),bg,mbg);
for(f=0.;f<40.;++f){
vec4 h=fract(sin(f+vec4(0.,3.,5.,8.))*1e4);
h.y=fract(h.y-t*.1);
vec3 p=(h.xyz-.5)*10.;
p.xz*=rot(t*.5);
float d=length(cross(p-ro,rd));
c+=vec3(.01)/d/d;
}
  out_color = vec4(c,1.);
}