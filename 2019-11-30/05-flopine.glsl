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

#define PI 3.141592
#define time fGlobalTime

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void moda (inout vec2 p, float rep)
{
  float per = 2.*PI/rep;
  float a = atan(p.y,p.x);
  float l = length(p);
  a = mod(a-per*0.5,per)-per*0.5;
  p = vec2(cos(a),sin(a))*l;
  }

float cyl (vec2 p, float r)
{return length(p)-r;}

float g1 = 0.;
float spike (vec3 p, float w)
{
  float per = .5;
  float id = floor(p.y/per);
  p.xz *= rot(id);
  p.y = mod(p.y, per)-per*0.5;
  float d = max(cyl(p.yz, 0.02-p.x*0.2),abs(p.x)-.5);
  g1 += 0.01/(0.01+d*d);
  return d;
 }

float prim1 (vec3 p)
{
  vec3 pp = p;
  p.xz*= rot(time);
  p.xz *= rot(p.y*1.2);
  moda(p.xz, 5.);
  p.x-=0.12;
  float d = cyl(p.xz, 0.07);

  p = pp;
  return min(d, spike(p,0.08));
 }

 float grid (vec3 p)
 {
   float per = 3.;
   p.xy *= rot(p.z*0.1);
   p = mod(p, per)-per*0.5;
   p.y += 0.5;
   float pr = prim1(p);
   p.yz *= rot(PI/2.);
   float pr2 = prim1(p);
   p.xy *= rot(PI/2.);
   return min(min(pr,pr2),prim1(p));
   }
 
   float g2 = 0.;
   float prim2 (vec3 p)
   {
     p.z -= time*4.;
     
     p.xy *= rot(time);
     p.xy = abs(p.xy)-1.+sin(time)*0.3;
     p.xz *= rot(time);
     float od = dot(p,normalize(sign(p)))-.2;
     g2 += 0.01/(0.01+od*od);
     return od;
     }
   
   float sdf (vec3 p)
   {
     return min(prim2(p),grid(p));
     }
   
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv += texture(texNoise,uv).r*0.1;
  vec3 ro = vec3(0.001,0.001,-4.+time*4.), p=ro,rd=normalize(vec3(uv,1.)), col = vec3(0.);
  
  float shad = 0;
  bool hit = false;
  for (float i=0.; i<100.; i++)
  {
    float d = sdf(p);
    if (d<0.001)
    {
      hit = true;
      shad = i/100.;
      break;
      }
      p += d*rd*0.6;
    }
    if (hit)
    {
      col = vec3(shad);
  
      }
    col += g1*vec3(0.2,0.5,0.2)*0.08;
      col += g2*vec3(0.3,0.,0.2);
  out_color = vec4(col, 1.);
}