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

// Hellow from Alkama's Lab 
//           _ _            
//       ,,,(O.O),,,        
//                          

#define sat(a) clamp(a, 0., 1.)
#define ao(a) sat(sc(p+n*a)/a)
#define ss(a) smoothstep(0., 1., sc(p+ld*a)/a)

const float pi = acos(-1);
const vec2 e = vec2(.001, 0);
const vec3 ro = vec3(0,2,-8.5);

float tt=mod(.4*fGlobalTime, 40.*pi);
float t = tt;

float torus(vec3 p, float r, float s) {
  vec2 b = vec2(length(p.xy)-r, p.z);
  return length(b)-s;
}
float box(vec3 p, vec3 s) { vec3 b=abs(p)-s; return max(max(b.x, b.y), b.z); }
mat2 rot(float a) { float c=cos(a),s=sin(a); return mat2(c,s,-s,c); }
vec2 moda(vec2 p, float r) {
  r = 2*pi/r;
  float a=mod(atan(p.y, p.x), r) -r*.5;
  return vec2(cos(a),sin(a))*length(p);
}
float sc(vec3 p) {
  vec3 po = p;
  
  float k = t*.1;
  p.xz *= rot(sin(cos(k)*pi+k)*pi);
  p.xy += .3*sin(t*.5)*sin(p.yz+tt*5);
  
  vec3 off = .1*(2*texture(texNoise, p.xz*.5).xyz-1);
  p+=off;
  
  for(int i=0; i<5+floor(mod(tt*.5, 8)); i++) {
    p = abs(p);
    p.xy *= rot(pi*.1);
    p.yz *= rot(pi*.1);
    p -= (i+1)*.08+.05*sin(t);
  }
  p.xz = moda(p.xz, 23.);
  p.yz = moda(p.yz, 22.);
  
  float tr= torus(p*.12, 1.23, .13);

  p.xz *= rot(-t);
  p.xy *= rot(-tt);
  
  float b = box(p, vec3(5., .2+.19*sin(tt), 1));
 
  float camex=length(po+off-ro) - 1.5;
  
  return max(min(b, tr), -camex);
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 tg = vec3(1.5*sin(t),0.5*cos(t*2),0);
  float z = .7 + .2*sin(tt*2);
  vec3 f= normalize(tg-ro);
  vec3 s=normalize(cross(vec3(.3*sin(tt),1,0), f));
  vec3 u=normalize(cross(f,s));
  vec3 rd = f*z+uv.x*s+uv.y*u; // << ohohhoho not normalizing that!
  vec3 col = vec3(0);
  float d=0;
  vec3 p = ro;
  for(int i = 0; i<300; i++) {
    float h = sc(p);
    if(h<.001) {
      vec3 n=normalize(vec3(sc(p)-vec3(sc(p-e.xyy), sc(p-e.yxy), sc(p-e.yyx))));
      vec3 ld = normalize(20*vec3(1,1,-1) - p);
      float fr = sat(pow(max(0., 1.+dot(n,rd)), 2.));
      vec3 bg = normalize(acos(sat(rd))*vec3(1.2, .8, 1.5))*(log(d)*i*.004);
      vec3 fg = vec3((ao(.1)+ao(.3))*.1 + ss(.2)*.75);
      col = fr*mix(fg, bg, fr)+bg;
      break;
    }
    if(d>100.) break;
    d+=h;
    p+=rd*h;
  }
  col *= sat(1.3-pow(length(uv), 2.));
  out_color = vec4(col, 1.);
}