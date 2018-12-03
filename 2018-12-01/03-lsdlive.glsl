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
vec3 re(vec3 p,float d){return mod(p-d*.5,d)-d*.5;}
void amod(inout vec2 p, float m){float a=re(atan(p.x,p.y),m);p=vec2(cos(a),sin(a))*length(p);}
void mo(inout vec2 p,vec2 d){p=abs(p)-d;if(p.y>p.x)p=p.yx;}

float sc(vec3 p, float d){p=abs(p);p=max(p,p.yzx);return min(p.x,min(p.y,p.z))-d;}


float g=0.;

float de(vec3 p){

p.xy*=r2d(time*.4);






vec3 q = p;




q = re(q,7.);
amod(q.xy, 6.28/5.);
mo(q.xy, vec2(4));
//q.xy+=1.;
float sc1 = sc(q,4.);

q =p;

amod(q.xy,6.28/2.);

mo(q.xy, vec2(.4));
float cyl = length(q.xy) - 1.;

q=p;
//q.z+=
float od = dot(p,normalize(sign(p)))-.3;

//return sc(q, .7);

p.xy *=r2d(p.z*.2);

amod(p.xy, 6.28/3.);



p.x = abs(p.x)- 4.;

p.xy*=r2d(p.z*.2);

amod(p.xy, 6.28/3.);
mo(p.xy, vec2(1));
p.x=abs(p.x)-1.;




float d= length(p.xy)-.2;
g+=.03/(.01+d*d);
d = min(d,sc1);

g+=.003/(.01+d*d);
d = min(d,cyl);

return d;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);




float t1=time*7.;
float s = sin(t1)*.1+t1*.1;
uv+=vec2(sin(s*2.)*.2*cos(s), sin(s)*.2);

uv*=r2d(time*.2);
//uv*=sin(time)*.1;



vec3 ro=vec3(0,0,-4+time*10),rd=normalize(vec3(uv,.7-length(uv))),p;
float t=0.,i=0.;
for(;i<1;i+=.02){p=ro+rd*t;float d = de(p);
//if(d<.001)break;
d=max(abs(d),.002);
t+=d*.8;}


vec3 c=mix(vec3(.2, .3, .3), vec3(.15, .1, .1), length(uv*sin(time)*20.)+i);
c.g+=sin(p.z*.2)*.5;
c+=g*.45 * vec3(.2, .1, .24);

  out_color = vec4(c,1);texture(texChecker, uv);;
}