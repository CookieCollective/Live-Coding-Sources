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

float g=0;
void mo(inout vec2 p,vec2 d){p.x=abs(p.x)-d.x;p.y=abs(p.y)-d.y;if(p.y>p.x)p=p.yx;}
float re(float p,float d){return mod(p-d*.5,d)-d*.5;}
void amod(inout vec2 p,float d){float a=re(atan(p.x,p.y),d);p=vec2(cos(a),sin(a))*length(p);}
#define time fGlobalTime
mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float de(vec3 p){

p=floor(p*15)/15;

//p.xz*=r2d(time);
p.xy*=r2d(time*.3);

vec3 q=p;
q.xy+=.4;
q.xy*=r2d(time);

q.xy*=r2d(q.z*.3);
//q.xy*=r2d(3.14*.25);
mo(p.xy, vec2(1, 2));
amod(p.xy, .785*.75);
mo(p.xy, vec2(.4, .2));
q.x=abs(q.x)-1.;
float cyl=length(q.xy)-.2;

q=p;
q.xy*=r2d(-time*1.8);
q.xy*=r2d(q.z*.3);
amod(q.xy,6.28/5);
q.x=abs(q.x)-4.8;
float cyl2=length(q.xy)-.4;


//p.xy*=r2d(sin(time*.3)*.9);
float d= cos(p.x)+cos(p.y)+cos(p.z);//+ texture(texNoise, p.xy).r*.2;
//d=max(d,-cyl3);
d=min(d,cyl);
d=min(d,cyl2);
g=.01/(.01+d*d);
return d;
return dot(p,normalize(sign(p)))-.6;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
float th=time*5.;
float s=2.5*(th*.1+sin(th*.1));
vec3 ro=vec3(0,0,-3+time),rd=normalize(vec3(uv,.7-length(uv))),p;
float t=0,i=0;
for(;i<1;i+=.01){p=ro+rd*t;float d=de(p);
//if(d<.001)break;
d=max(abs(d),.005);
t+=d*.4;

}
vec3 c=mix(vec3(.9,.5,.2),vec3(.1,.2,.1), sin(uv.x*5.)+i);
c.r+=sin(p.z*.4)*.8;
c+=g*1;
c=mix(c,vec3(.1,.15,.22),1-exp(-.01*t*t));
  out_color = vec4(c,1);;
}