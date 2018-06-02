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


#define time fGlobalTime

mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}

float re(float p,float d){return mod(p-d*.5,d)-d*.5;}

void amod(inout vec2 p,float d){float a=re(atan(p.x,p.y),d);p=vec2(cos(a),sin(a))*length(p);}

float sc(vec3 p,float d){
p=abs(p);
p=max(p,p.yzx);
return min(p.x,min(p.y,p.z))-d;
}

void mo(inout vec2 p,vec2 d){
p.x=abs(p.x)-d.x;
p.y=abs(p.y)-d.y;
if(p.y>p.x)p.yx=p;
}

float g=0.;
float de(vec3 p){
float t=time*4.;
//p.y+=.5;
float s=t*.1+sin(t)*.1;


p.xy*=r2d(time);//.77+s*2.5);

//p.xz*=r2d(.77+s*2.5);
//p.xy*=r2d(.77+s*2.5);

p.xy*=r2d(p.z*.1);

p.z=re(p.z,2);

amod(p.xy,6.28/5.);

mo(p.xz,vec2(.3, 1.3));
mo(p.xy,vec2(2.2, 1.5+sin(.77+t*.5)*.2));

float sc2 =sc(p,1.3);

amod(p.xy,6.28/3.4);



mo(p.xy,vec2(1.3, .2));

//p.x=abs(p.x)-1;
//p.y=abs(p.y)-1;

float d= sc(p,.4);

d=max(d,-sc2);

g+=.01/(.02+d*d);
return d;
return dot(p,normalize(sign(p)))-.6;
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

vec3 ro=vec3(0,0,-3+time*4);
vec3 rd=normalize(vec3(uv,1));

float t=0,i=0;
vec3 p;
for(;i<1;i+=.01){
p=ro+rd*t;
float d=de(p);
//if(d<.001)break;
d=max(abs(d),.02);
t+=d*.4;
}

vec3 c =mix(vec3(.7,.3,.4),vec3(.1,.4,.2),uv.x+i);
c+=g*.02;
c.r+=sin(p.z)*.3;
c=mix(c,vec3(.2,.1,.2),1-exp(-.01*t*t));
c*=1.2;
  out_color = vec4(c,1);
}