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

float sc(vec3 p,float d){p=abs(p);p=max(p,p.yzx);return min(p.x,min(p.y,p.z))-d;}

float re(float p,float d){return mod(p-d*.5,d)-d*.5;}

void mo(inout vec2 p,vec2 d){
  p=abs(p)-d;
  if(p.y>p.x)p=p.yx;
}


void amod(inout vec2 p,float a){
  float m=re(atan(p.x,p.y),a);
  p = vec2(cos(m),sin(m))*length(p);
}


float g;
float g1;
float de(vec3 p){
 // p.xz*=r2d(time);
  //p.xy*=r2d(time*.5);
  
  p.z=re(p.z,1.5
  );
  
  
  p.x=abs(p.x)-2.;
  p.xy*=r2d(time);
  
  amod(p.xy, 6.28/5.);
  
  //p.xy*=r2d(p.z*.5);
  //p.x=abs(p.x)-8.;
  
  
  vec3 q=p;
  //p.xy*=r2d(p.z*.3);
  p.x=abs(p.x)-4;
  amod(p.xy, 6.28/7.);
  mo(p.xz, vec2(1, 2));
  mo(p.xy, vec2(1.2, 2.));
  amod(p.xy, 6.28/3.);
  p.xy*=r2d(p.z*.3);
  p.x = abs(p.x) - 1;
  p.xy*=r2d(3.14*.25);
  
  float d1 = sc(p,.2);
  
  g1+=.01/(.01+d1*d1);
  
  
  p=q;
  
  re(p.z,2.);
amod(p.xy, 6.28/8.);
mo(p.xy, vec2(7));
  amod(p.xy, 6.28/3.);
  mo(p.xy, vec2(1, 2));
  float d2 = dot(p,normalize(sign(p)))-.5;
  
  float d = min(d2,d1);
  

  g+=.01/(.01+d2*d2);
  
  p=q;
  
  p.xy*=r2d(p.z*.1);
  p.x=abs(p.x)-8.;
  d = min(d,length(p.xy)-1.);
  g+=.01/(.01+d2*d2);
  
  return d;
  
  return length(p)-.5 - sin(time);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv*=sin(time);
  uv*=r2d(time*2);
  
  
  vec3 ro=vec3(0,0,-3 + time * 12.),rd=normalize(vec3(uv,.3-length(uv) + tan(sin(time*2.)))),p;

  float t=0,i=0.;
  for(;i<1;i+=.01){
    p=ro+rd*t;;
    float d=de(p);
    //if(d<.001) break;
    d=max(abs(d),.001);
    t+=d*.3;
  }
vec3 c=mix(vec3(.9, .3, .2), vec3(.4,.12,.1), length(7.*uv.x)+i);
  
  c+=g*.04;
  c+=g1*.1*vec3(.1, .5, .5);
  out_color = vec4(c,1);
}