#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNogozon;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define rand(x) fract(sin(x)*1e4)

float C,S;
#define rot(a) mat2(C=cos(a),S=sin(a),-S,C)

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

struct M{
  float d,md;
vec3 c;
};

vec3 camera(vec3 p) {
  float t=mod(fGlobalTime*.2,2),
  a=smoothstep(0.,.8,t)+smoothstep(1.,1.8,t);
  p.xz*=rot(a*3.14159);
  return p;
}

vec3 cIn=vec3(1,.7,0),
cOut=vec3(1,.5,.5);
float f;

float pl(vec3 p,vec3 o,vec3 d) {
  return dot(p-o,normalize(d));
}

M map(vec3 p){
  p.x=abs(p.x);
p.y+=.4+sin(fGlobalTime)*.2;
  float d=max(pl(p,vec3(0,0,.5),vec3(1,1,1)),pl(p,vec3(0,.05,0),vec3(0,1,0)));
  d=min(d,max(pl(p,vec3(0,0,-.1),vec3(1,1,1)),pl(p,vec3(0,.1,0),vec3(0,1,0))));
  d=max(d,pl(p,vec3(0.2,0,0),vec3(3,1,0)));
  d=max(d,pl(p,vec3(0.2,0,0),vec3(1,-3,0)));
  d=max(d,pl(p,vec3(0,0,-.5),vec3(0,1,-5)));
  
  M m;
m.d=d;
  m.c=mix(cIn,cOut,f/30.);
  m.md=.01;
return m;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 co = camera(vec3(0, 0, -3)),
  cd = camera(normalize(vec3(uv, 1)));

  float acc=0;
  for (f=0;f<128;++f) {
    float r=rand(f)*128+fGlobalTime,fr=fract(r),fl=floor(r);
    vec4 rr=rand(fl+vec4(0,3,5,8));
    vec3 ro=vec3(vec2(1,0)*rot(rr.x*6.2835)*(2+12*rr.y),0),
      rd=vec3(0,0,1),
      coro=co-ro,
      n=normalize(cross(cd,rd)),
      nc=cross(n,cd),
      nr=cross(n,rd);
    float d=dot(coro,n),
      tc=-dot(coro,nr)/dot(cd,nr),
      tr=dot(coro,nc)/dot(rd,nc);
    acc+=.05/d/d*step(0,tc)*smoothstep(5,0,abs(tr-mix(50,-50,fr)));
  }

  vec3 bgC=acc*vec3(.5,.5,1);

  vec3 mp=co,foC=vec3(0);
  float md=10;
  for (f=0;f<30;++f){
    M m=map(mp);
  md=min(md,m.d);
    if(m.d<.01)
      foC+=m.c;
    mp+=cd*max(m.d,m.md);
  }
  
foC/=10;

  vec3 c=mix(
    foC,
    mix(cOut,bgC,smoothstep(0.,0.1,md)),
    step(0,md));

  out_color = vec4(c,1);
}