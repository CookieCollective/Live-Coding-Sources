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
vec2 sc,e=vec2(.00035,-.00035);float t,tt;vec3 pos;
float mx(vec3 p){return max(max(p.x,p.y),p.z);}
float bo(vec3 p, vec3 r){return mx(abs(p)-r);}
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
vec2 fb( vec3 p)
{
vec2 h,t=vec2(0.8*bo(p,vec3(1,.5,6)),5);
t.x=min(t.x,0.8*bo(p-vec3(1,0,0),vec3(.2,1,1.5)));
t.x=min(t.x,0.8*bo(p+vec3(1,0,0),vec3(.2,1,1.5)));
h=vec2(0.8*bo(abs(p)-vec3(.25,0,.25),vec3(.15,1,1.4)),3);
t=(t.x<h.x)?t:h;
  return t;
}
vec2 mp( vec3 p)
{
p.z=mod(p.z+tt*10,50)-25;
p.yx*=r2(sin(p.z*0.05+tt*1)*2);
pos=p;
pos.z=mod(p.z+tt*5,25)-12.5;
float att=clamp(length(p)-1.5,4,13);
for(int i=0;i<4;i++){
pos=abs(pos)-vec3(0.5+att*0.3,0.5+att*0.1,2);
pos.xy*=r2(abs(cos(p.z*0.05*float(i))));
}

vec2 t=fb(pos);
t.x=max(t.x,bo(p,vec3(15,15,23)));
  return t;
}
vec2 tr( vec3 ro,vec3 rd)
{
vec2 h,t=vec2(0.1);
for(int i=0;i<128;i++){
h=mp(ro+rd*t.x);
if(h.x<.0001||t.x>60) break;
t.x+=h.x;t.y=h.y;
}
if(t.x>60) t.x=0;
  return t;
}
float noise(vec3 p){
vec3 ip=floor(p),s=vec3(7,157,113);
p-=ip;
vec4 h=vec4(0,s.yz,s.y+s.z)+dot(ip,s);
p=p*p*(3-2*p);
h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
h.xy=mix(h.xz,h.yw,p.y);
return mix(h.x,h.y,p.z);
}
void main(void)
{
tt=mod(fGlobalTime,100);
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

vec3 ro=vec3(0,0,-2),
rd=normalize(vec3(uv,1)),co,fo,ld=normalize(vec3(.5,.5,-.5));co=fo=vec3(.9);

sc=tr(ro,rd);t=sc.x;
if(t>0){
vec3 po=ro+rd*t,
no=normalize(e.xyy*mp(po+e.xyy).x+
e.yyx*mp(po+e.yyx).x+
e.yxy*mp(po+e.yxy).x+
e.xxx*mp(po+e.xxx).x),al=vec3(.5);
if(sc.y<5) al=vec3(1,.5,0);
float dif=max(0,dot(no,ld)),
aor=t/50,
ao=exp2(-2*pow(max(0,1-mp(po+no*aor).x/aor),2)),
specPo=exp2(5-3*noise(pos/vec3(.2)));
float fresnel=pow(1+dot(no,rd),4);
vec3 sss=vec3(.5)*smoothstep(0,1,mp(po+ld*0.4).x/0.4),
spec=vec3(5)*pow(max(0,dot(no,normalize(ld-rd))),specPo)*specPo/32;
co=spec+al*(ao*0.8+0.2)*(dif+sss);
}

  //float f = texture( texFFT, d ).r * 100;
 
 out_color = vec4(pow(co,vec3(0.45)),1);
 //out_color = vec4(vec3(0.45),1);
}