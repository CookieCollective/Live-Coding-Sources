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

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}

float box(vec3 p,vec3 b){
    vec3 q= abs(p)-b;
    return length(max(vec3(0.),q))+min(0.,max(q.x,max(q.y,q.z)));
}
vec2 sdf(vec3 p){
  vec3 op = p;
  float bt = texture(texFFTIntegrated,.33).r*.2;
  vec2 l = vec2(atan(p.z,abs(p.x)),p.y);
   p += vec3(5,2.,-2.0);
   p.xy *= rot(-.785*sin(floor(bt)));
  
  float tt = texture(texNoise,p.xy*.1+bt).r;
  
  
  float ttt = texture(texFFT,atan(p.x,p.z)+tt*4+fGlobalTime).r;
  tt = floor(tt*100)/100;
  ttt = sqrt(ttt);
  vec2 h;

  h.x = length(p)-5.-tt;
  h.y = 1.-(ttt);
  
  vec2 t;
   
  op.x -=2.;
   
   op.z = mod(op.z,5)-2.5;
   
   op.y +=sin(op.z*5+bt*10);
  
   op.xy *=rot(floor(fGlobalTime+bt*20));
   op.xz *=rot(floor(bt*20)*1.33);
   
   
  t.x = box(op,vec3(.9));
  t.y = 2.;
  
  h = t.x < h.x ? t:h;
  
  return h;
  }
vec2 nv=vec2(-.001,.001);
#define q(s) s*sdf(p+s).x
vec3 norm(vec3 p){return normalize(q(nv.xyy)+q(nv.yyx)+q(nv.yxy)+q(nv.xxx));}

vec3 pal(float t){return .5+.5*cos(6.28*(1.*t+vec3(.0,.3,.7)));}
// Art of code <3
float h21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return fract((a.x + a.y) * a.z);
}
void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
   vec2 puv = uv;
  
  
   vec3 ro=vec3(.0,.0,-5.),rd=normalize(vec3(uv,1.)),rp=ro;
  vec3 light = vec3(1.,2.,-3.);
   
   float bt = texture(texFFT,.2).r;
  
   float tt = texture(texFFT,floor(abs(uv.x)*100)/100).r;
   tt =sqrt(tt)*3;
  
   vec3 col= vec3(tt)*sqrt(pal(tt));
  vec3 acc = vec3(0.);
  
  for(float i=0.;i<=69.;i++){
      vec2 d = sdf(rp);
      
     if(d.y <=.92+sin(fGlobalTime)*.04){
       acc += pal(d.y*1.2+fGlobalTime*.1)*max(0.,exp(10*-abs(d.x))/(25.-d.y*20))*exp(-abs(i/20));
       d.x  = max(0.01,abs(d.x));
     } 
     if(d.y == 2.) {
       
        acc += vec3(.1,.8,.4)*max(0.,exp(1*-abs(d.x))/(69.-bt*8000.));
        d.x  = max(0.1,abs(d.x));
      }
    
      rp +=rd*d.x;
      if(d.x <=.001){
                 vec3 n = norm(rp);
           float fre  = pow(1.-dot(-rd,n),5.);
           if(d.y <=1.){
  
           col = fre*vec3(.1,.5,.8)+vec3(.3)*max(0.,dot(n,normalize(light-rp)));
           break; // CA ME TURA UN JOUR CET OUBLIE
             
           } else {
              //col = vec3(1.3)*max(0.,dot(n,normalize(light-rp)));
             //break;
             }
        }
    
    }
    
    
    
  // puv = (puv *  vec2(v2Resolution.y / v2Resolution.x, 1))+.5;
    
vec2 puvr = (puv*vec2(1.1) *  vec2(v2Resolution.y / v2Resolution.x, 1))+.5;
  vec2   puvg = (puv *vec2(1)*  vec2(v2Resolution.y / v2Resolution.x, 1))+.5;
  vec2   puvb = (puv*vec2(.9) *  vec2(v2Resolution.y / v2Resolution.x, 1))+.5;
   vec3 pcol =vec3(texture(texPreviousFrame,puvr).r,
    texture(texPreviousFrame,puvg).g,
    texture(texPreviousFrame,puvb).b
    );
    
    
    
    col = mix(col,pcol,.5+fract(fGlobalTime*4)*.4);
  col+=acc;
	out_color = vec4(col,1.);
}