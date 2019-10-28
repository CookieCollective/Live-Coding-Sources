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
vec2 s,v,e=vec2(.00035,-.00035);float t,tt,g,d01;vec3 np,pp,bp,al,po,no,ld;
vec4 c=vec4(0,5,10,0.2);
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
vec2 ball( vec3 p,float d,float mm,float mul,float bro)
{
  p.z=mod(p.z+tt*10,30)-15;
  bp=p*.28;p*=bro;  
  d01=d*.5+.5;
  vec2 h,t=vec2(length(p)-5,3);
  t.x=max(t.x,-bo(p,vec3(2.8*mul)));
  t.x=min(t.x,length(p)-2*mul);
  t.x=abs(t.x)-.3;  
  pp=p;pp.xy*=r2(sin(p.z*.2)+tt*(2-d01)*d)*(mul*.5+.5);
  t.x=max(t.x,bo(abs(abs(p)-vec3(0,0,2))-vec3(0,0,1),vec3(10,3,.6)));
  np=p;
  np.xy*=r2(mix(tt,1.59+sin(tt*.5),d01)*d);
  t.x=max(t.x,np.x);
 
  h=vec2(length(p)-5,mm);
  h.x=max(h.x,-bo(p,vec3(2.8*mul)));
  h.x=min(h.x,length(p)-2*mul);
  h.x=abs(abs(h.x)-.1)-.05;  
  h.x=max(h.x,bo(abs(abs(p)-vec3(0,0,2))-vec3(0,0,1),vec3(10,4,.7)));
  h.x=max(h.x,np.x);
  t=mix(t,h,step(h.x,t.x));
  t/=bro*1.5;
  return t;
}
vec2 mp( vec3 p)
{
  vec2 h,t=ball(p,-1,6,1,1);
  h=ball(p,1,5,1,.28);
  t=mix(t,h,step(h.x,t.x));
  h=ball(p,-1,6,-1,.19);
  t=mix(t,h,step(h.x,t.x));
  h=vec2(length(p.xy)-.5,3);
  t=mix(t,h,step(h.x,t.x));
  pp=bp;pp.xy*=r2(-tt+sin(pp.z));
  h=vec2(bo(pp,vec3(30,0.001,0.01)),6);
  g+=0.1/(0.1+h.x*h.x*40);
  t=mix(t,h,step(h.x,t.x));
  return t;
}
vec2 tr( vec3 ro,vec3 rd )
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
    if(h.x<.0001||t.x>120) break;    
    t.x+=h.x;t.y=h.y;
  } 
if(t.x>120) t.x=0;  
  return t;
}
float a(float d){return clamp(mp(po+no*d).x/d,0.,1.);}
float ss(float d){return smoothstep(0.,1.,mp(po+ld*d).x/d);}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
tt=mod(fGlobalTime,62.83);
  vec3 ro=vec3(cos(tt*.5)*3,16+sin(tt)*3,-10),
  cw=normalize(vec3(0)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),
  cv=normalize(cross(cu,cw)),
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;
  ld=normalize(vec3(.4,.7,-.2));
  co=fo=vec3(.3);
  s=tr(ro,rd);t=s.x;
  if(t>0){
    po=ro+rd*t;
    no=normalize(e.xyy*mp(po+e.xyy).x+
    e.yyx*mp(po+e.yyx).x+
    e.yxy*mp(po+e.yxy).x+
    e.xxx*mp(po+e.xxx).x);
    al=mix(vec3(.25,.5,.0),vec3(0,.2,.3),min(length(bp)-2.5,1));
    
    float dif=max(0,dot(no,ld)),
    spo=20,
    fr=pow(1+dot(no,rd),4),
    sp=pow(max(dot(reflect(-ld,no),-rd),0),spo);
    co=mix(sp+al*(a(.2)*a(.4)+.2)*(dif+ss(.4)+ss(2)),fo,min(fr,.2));
    co=mix(fo,co,exp(-.00001*t*t*t));
  }
  
  out_color = vec4(pow(co+g*.3,vec3(.45)),1);
}