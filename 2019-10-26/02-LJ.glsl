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
vec2 amod(vec2 p,float a){a=mod(atan(p.x,p.y),a)-a*.5;return vec2(cos(a),sin(a))*length(p);}
float so(vec3 p){return dot(p,normalize(sign(p+1e-6)));}
float map( vec3 p) {
  vec3 o=p;
  
  p.z=mod(p.z,4.)-2.;
  p.xy*=r2d(time*sign(mod(o.z,8.)-4.));
  //p.x=max(abs(p.x)-.5,0.)-1.;
  p.yx=amod(p.xy,.5);
  p.y=max(abs(p.y)-1.,0.);
  p.z=max(abs(p.z)-.5,0.)-.5;
  for(int i=0;i<5;i++)
    p=max(abs(p)-vec3(.0,.1-sin(o.z*.1)*.2,-.1),0.)-vec3(.2,.2,.5),p.xy*=r2d(.4),p.xz*=r2d(.7);
  return max(so(p)-.15-texture(texFFTSmoothed,.05).r*10.,-so(max(abs(o.xyy)-sin(32.+o.z*.07)*.1,0.))+1.);-max(-o.y-1.,0.);
  
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  if(fract(time*.2)<.5)uv=abs(amod(uv,2.09)),uv.x=abs(uv.x)-texture(texFFTSmoothed,.02).r*10.;
  uv.x+=texture(texTex2,uv.yy*100.).r*texture(texFFT,.5).r;
  vec2 p=uv;
  vec3 ro=vec3(0,.0,-time*2.-texture(texFFTIntegrated,.22).r*25.),rd=normalize(vec3(2*p*r2d(texture(texFFTIntegrated,.1).r*5.),-1.-texture(texFFT,.01).r*2.)),mp;
  float md;mp=ro;int ri;
  for(int i=0;i<100;i++)if(ri=i,mp+=rd*(md=map(mp)),md<.001)break;

  out_color = vec4(float(ri)/100.)*mix(vec4(.4,.5,.7,1),vec4(.7,.5,.3,1),length(uv)+texture(texNoise,uv+time).r)*2.;
}