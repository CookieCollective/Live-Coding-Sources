#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

in vec2 out_texcoord;
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI acos(-1.)
#define rot(a) mat2(cos(a),-sin(a), sin(a),cos(a))
#define rep(p,c) p = mod(p, c)-c*.5

#define time fGlobalTime

float se;
float zl;
float rd(){return fract(sin(se+=1.)*3424.43);}
vec3 vr(){float sd = rd()*6.28;
  float sa = rd();
  float a  = sqrt(1.-sa*sa);
  vec3 rn = vec3(a*cos(sd),a*sin(sd),(sa-0.5)*2.);
  return rn*sqrt(rd());}
float dl(vec3 p, float r){
  p = pow(abs(p),vec3(r));
  return pow(p.x+p.y+p.z,1/r);
}
float ld(vec3 p,vec3 a, vec3 b,  float r){
  vec3 pa = p-a;vec3 ba  =b-a;
  float h = clamp(dot(pa,ba)/dot(ba,ba),0.,1.);
  return dl(pa-ba*h,10.)-r;}
  
float map(vec3 p){
  float d2 = length(p-vec3(0.,20.*sign(sin(time*16.)),0.))-10.;
  for(int i = 0; i < 7 ; i++){
    p.xy *= rot(0.3+((time*1.9)*0.5+0.5));
    p.yz *= rot(0.3+(sin(texture(texFFTIntegrated,1.).x*.6)*0.5+0.5));
    p.x = abs(p.x)-1.2;
    p -= 0.3;
  }
  zl = d2;
  float d1 = ld(p, vec3(0.),vec3(0.,5.,0.),smoothstep(5.,0.,p.y)+(sin(p.y*4.)*0.5+0.5)*0.2);
  return min(d2,d1);}
float rm (vec3 p, vec3 r){
  float dd = 0.;
  for (int i = 0; i < 40 ; i++){
    float d = map(p);
    if(dd>30.){dd=30.; break;}
    if(d<0.01){break;}
    p +=r*d;
    dd += d;}
    return dd;
  }
vec3 nor(vec3 p){ vec2 e  = vec2(0.01,0.);return normalize(map(p)-vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx)));}

void main(void)
{
	vec2 uv = out_texcoord;
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
se = uv.x*v2Resolution.y+uv.y;
  se += time;
vec3 p = vec3(0.,0.,-12.);  
   vec3 r = normalize(vec3(uv,1.));
  float r1 = 0.;
  float dd = 0.;
  for(int i = 0; i<4; i++){
    
        float d = rm(p,r);
    if(i==0){ dd = d;}
          if(step(0.4,zl)>0.){
            vec3 pp = p + r*d;
            vec3 n = nor(pp);
            r = n * vr();
            p = pp + 0.1* r;
          }
          else{r1 = 1.; break;}
        }
        float m = smoothstep(19.,18.,dd);
        float d2 = max(r1,texture(texPreviousFrame,out_texcoord+vec2(0.001)).x*0.9);
        
        out_color = vec4(vec3(r1+d2*mix(0.5,1.,1-m)),d2);
       
}