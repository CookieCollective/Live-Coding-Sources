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
vec2 s,v,e=vec2(.00035,-.00035);float t,tt,b,bb,g,g2;vec3 np,bp,pp,po,no,al,ld;
float bo(vec3 p, vec3 r){p=abs(p)-r;return(max(max(p.x,p.y),p.z));}
mat2 r2 (float r){ return mat2(cos(r),sin(r),-sin(r),cos(r));}
vec4 c=vec4(0,5,15,.2);
vec2 fb( vec3 p )
{
  vec2 h,t=vec2(bo(p,vec3(2,5,1)),5);
  t.x=abs(t.x)-.2;
  t.x=max(t.x,p.z-0.3);
  
  h=vec2(bo(p,vec3(2,5,1)),6);
  h.x=abs(h.x)-.1;
  h.x=max(h.x,p.z-0.6);
  
  t=t.x<h.x?t:h;
  t.x=max(t.x,-bo(p,vec3(1.5,4.5,5)));
  
  h=vec2(length(abs(p)-vec3(0,2.5,0))-1.5,5);
  t=t.x<h.x?t:h;
  h=vec2(length(abs(p.xy)-vec2(0,2.5))-.1,3);
  t=t.x<h.x?t:h;
  
  h=vec2(length(abs(p.xy)-vec2(2,2))-.02,6);
  g+=0.1/(0.1+h.x*h.x*40);
  t=t.x<h.x?t:h;
  t.x*=0.7;
  return t;
}
vec2 mp( vec3 p )
{
  p.xy*=r2(sin(p.z*.2)*.3);
  np=p;
  np.z=mod(np.z+tt*3,10)-5;
  for(int i=0;i<4;i++){
    np=abs(np)-vec3(4,2.,0);
    np.xy*=r2(.785/2);
    np.xz*=r2(-.05);
  }
  vec2 h,t=fb(np);
   h=vec2(length(abs(p.xy)-vec2(4,2))-.1,6);
  g2+=0.1/(0.1+h.x*h.x*(40-sin(p.z*.4+tt*2.)*39.8));
  t=t.x<h.x?t:h;
  h=vec2(length(cos(p+np*.2-vec3(0,tt,0)))-.01,6);
  g2+=0.1/(0.1+h.x*h.x*400);
  t=t.x<h.x?t:h;
  return t;
}
vec2 tr( vec3 ro, vec3 rd )
{
  vec2 h,t=vec2(.1);
  for(int i=0;i<128;i++){
    h=mp(ro+rd*t.x);
    if(h.x<.0001||t.x>100) break;
    t.x+=h.x;t.y=h.y;
  }
  if(t.x>100) t.y=0;
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  //float f = texture( texFFT, d ).r * 100;
tt=mod(fGlobalTime,62.83);
  
  vec3 ro=mix(vec3(1),vec3(-1,-1,1),ceil(sin(tt*.4)))*vec3(cos(tt*.2)*3,5,-20.),
  cw=normalize(vec3(0)-ro),
  cu=normalize(cross(cw,vec3(0,1,0))),
  cv=normalize(cross(cu,cw)),
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;
  co=fo=vec3(.1)-length(uv)*.1;
  ld=normalize(vec3(.2,.3,-.4));
  
  s=tr(ro,rd);t=s.x;
  if(s.y>0){
    po=ro+rd*t;
    no=normalize(e.xyy*mp(po+e.xyy).x+
    e.yyx*mp(po+e.yyx).x+
    e.yxy*mp(po+e.yxy).x+
    e.xxx*mp(po+e.xxx).x);al=vec3(.1,.2,.4);
    if(s.y<5) al=vec3(0);
    if(s.y>5) al=vec3(1);
    float dif=max(0,dot(no,ld)),
    fr=pow(1+dot(no,rd),4),
    sp=pow(max(dot(reflect(-ld,no),-rd),0),30);
    co=mix(sp+al*(a(.1)*a(.4)+.2)*(dif+s(2)+s(4)),fo,min(fr,.5));
    co=mix(fo,co,exp(-.0001*t*t*t));
  }
  out_color = vec4(pow(co+g*.2+g2*vec3(.1,.2,.4)*.2,vec3(.45)),1);
}