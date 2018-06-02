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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}



vec2 path(float t){
float a=sin(1.5+t*.2),b=sin(t*.2);
return vec2(2*a,a*b);
}

float g=0.;

float dt=0.;
float re(float p,float d){return mod(p-d*.5,d)-d*.5;}
void amod(inout vec2 p,float d){float a=re(atan(p.x,p.y),d);p=vec2(cos(a),sin(a))*length(p);}
void mo(inout vec2 p,vec2 d){p.x=abs(p.x)-d.x;p.y=abs(p.y)-d.y;if(p.y>p.x)p=p.yx;}
#define time fGlobalTime
mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float sc(vec3 p,float d){p=abs(p);p=max(p,p.yzx);return min(p.x,min(p.y,p.z))-d;}
float de(vec3 p){

p.xy-=path(p.z);


//p.y+=.5;
float t=time*9;
float s=.77+2.5*(t*.1+sin(t)*.1);
//p.xz*=r2d(s);
//p.xy*=r2d(s);

vec3 q=p;
q.xy*=r2d(q.z*.3);
amod(q.xy, 6.28/3.);
q.x=abs(q.x)-1.1;
float cyl = length(q.xy)-.08;

q=p;
q.z-=3.+dt;
q.xy+=.1*vec2(cos(p.z*.2)*sin(p.z*.2),sin(p.z*.1));
q.xz*=r2d(s);
q.xy*=r2d(s);
float od=dot(q,normalize(sign(q)))-.3;

p.xy*=r2d(-p.z*.1);

mo(p.xy,vec2(.5, .3));

amod(p.xy, 6.28/3.);

//p.xy*=r2d(p.z*.1);

p.z=re(p.z,2);
mo(p.xy,vec2(.4, 1.));

amod(p.xy, .785*.75);
//mo(p.xz,vec2(54, 4));


//p.x=abs(p.x)-1;

p.xy *= r2d(3.14*.25);
float d= sc(p, .2);

d= min(d,cyl);

d=min(d,od);
g+=.01/(.01+d*d);
return d;
return length(p)-1;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

dt=time*7.;

vec3 ro=vec3(0,0,-3+dt);
//rd=normalize(vec3(uv,.8-length(uv)))
vec3 p;

vec3 ta=vec3(0,0,dt);

ro.xy+=path(ro.z);
ta.xy+=path(ta.z);

vec3 f=normalize(ta-ro);
vec3 l=cross(vec3(0,1,0),f);
vec3 u=cross(f,l);
vec3 rd=normalize(f+uv.x*l+uv.y*u);

float t=0,i=0;
for(;i<1;i+=.01){p=ro+rd*t;float d=de(p);
if(d<.001)break;
t+=d*.5;
}


vec3 c=mix(vec3(.9,.3,.2), vec3(.1,.1,.2), sin(uv.x*3.)+i);
c.g+=sin(p.z)*.2;
c+=g*.025;
c=mix(c,vec3(.1,.1,.2),1-exp(-.004*t*t));
  out_color = vec4(c,1);;
}