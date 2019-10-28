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
//evvvvil
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
vec2 s,v,e=vec2(.00035,-.00035);float t,tt,g,bb,mm,noi;vec3 po,no,al,ld;
vec4 np,c=vec4(0,0,14,0.2);
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);}
mat2 r2(float r){ return mat2(cos(r),sin(r),-sin(r),cos(r));}
float smin(float a,float b,float h){
  float k=clamp((a-b)/h*.5+.5,0.,1.);
  return mix(a,b,k)-k*(1-k)*h;

  }
  vec2 smin2(vec2 a,vec2 b,float h){
  float k=clamp((a.x-b.x)/h*.5+.5,0.,1.);
  return mix(a,b,k)-k*(1-k)*h;
}
  vec2 syn( vec3 p)
{
  p.x-=sin(p.y*15+tt*10)*0.03;
  noi=texture(texNoise,vec2(.1,.2)*vec2(p.y,dot(p.xz,vec2(.7)))).r;
  bb=cos(p.y*.25+tt*2)*.5+.5;
  float h,t=length(p.xz-(sin(p.xz*1.5-tt)*.5+cos(p.y*2+noi*5-tt)*.3))-(1+bb*2);
  p=abs(p)-(1+bb*2);
  p.xy*=r2(-.5);
  p.yz*=r2(.5);
  p+=cos(p.y)*.2;
  h=length(p.xz)-(.4+.3*sin(p.y*.5+noi*3)+.3*(.5+.5*sin(p.y*2-tt*3)));
  t=smin(t,h,.5);
  return vec2(t*.5,bb);
}
vec2 mp( vec3 p)
{
  np=vec4(p,1);
  mm=sin(tt-p.y*.5)*2;
  vec2 h,t=syn(p);
  for(int i=0;i<2;i++){
    np*=2;
    np.xyz=abs(np.xyz)-vec3(8.5+mm,8.5,8.5+mm);
    np.xy*=r2(-.4);
    np.yz*=r2(.2);
    h=syn(np.xyz);
    h.x/=np.w;
    t=smin2(t,h,0.5);
  }
  np.xz*=r2(.785);
  h=vec2(bo(abs(np.xyz)-3.*mm,vec3(0,100,0)),1.);
  g+=0.1/(0.1+h.x*h.x*.2);
  h.x=h.x*0.7/np.w;
  t=t.x<h.x?t:h;
  bb=texture(texNoise,p.xz*.1).r;
  h=vec2(0.5*length(p+vec3(0,70,0)-mm+bb*3)-30,1-bb*3);
  t=smin2(t,h,.5);
  
  return t;
}
vec2 tr( vec3 ro,vec3 rd )
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
    if(h.x<.0001||t.x>30) break;
    t.x+=h.x;t.y=h.y;
  }
  if(t.x>30) t.x=0;
  return t;

}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  tt=mod(fGlobalTime,62.83);
  vec3 ro=vec3(cos(tt*c.w+c.x)*c.z,-5+cos(tt*.2)*5,sin(tt*c.w+c.x)*c.z),
  cw=normalize(vec3(0,sin(tt*.4)*10,0)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),
  cv=normalize(cross(cu,cw)),
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;
  ld=normalize(vec3(.1,.3,0));
  v=vec2(abs(atan(rd.x,rd.z)),rd.y);
  co=fo=vec3(.2)+texture(texNoise,v*.4).r*.5;;
  
  s=tr(ro,rd);t=s.x;
  
  if(t>0){
    po=ro+rd*t;
    no=normalize(e.xyy*mp(po+e.xyy).x+
    e.yyx*mp(po+e.yyx).x+
    e.xxx*mp(po+e.xxx).x+
    e.yxy*mp(po+e.yxy).x);
    al=mix(vec3(.3,.6,.9),vec3(.6,.3,.2),bb*3);
    float dif=max(0,dot(no,ld)),
    fr=pow(1+dot(no,rd),4),
    sp=pow(max(dot(reflect(-ld,no),-rd),0),30);
    co=mix(sp+al*(a(.2)*a(.4)+.2)*(dif+s(.4)+s(2)),fo,min(fr,.5));
    co=mix(fo,co,exp(-.0002*t*t*t));//fog
  }
  
  out_color = vec4(pow(co+g*0.1,vec3(.45)),1);
}