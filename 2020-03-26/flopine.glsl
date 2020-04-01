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
#define TAU (2.*PI)
#define time fGlobalTime

#define blipbloop texture(texFFT, 0.01)

void mo (inout vec2 p, vec2 d)
{
  p = abs(p)-d;
  if(p.y>p.x) p = p.yx;
  }

  float hash21(vec2 x)
  {return fract(sin(dot(x,vec2(12.35,18.5)))*1245.5);}
  

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float plane (vec3 p, vec3 n)
{return dot(p,normalize(n));}

float lily (vec3 p)
{
  float a = atan(p.z,p.x);
  p.y += (mod(a, TAU/5.))*0.15;
   return cyl(p.xzy, 3.,0.15);
  }
  
  // NO WAS NOT PLANNED
  
  float flower (vec3 p)
  {
    p.y += sin(length(p.xz*2.)-time*blipbloop.r)*0.3;
    mo(p.xz, vec2(.5));
    mo(p.xy, vec2(.5));
    mo(p.yz, vec2(.3));
    return plane(p, vec3(0.5,0.5,1.));
    }

  float water (vec3 p)
  {
    p.y += 1.2;
    p.y += texture(texNoise, p.xz*0.06+time*0.02).r + texture (texNoise, p.xz*0.05-time*0.01).r;
    return abs(p.y)-1.;
    }
  
    float li,wat, flo;
float SDF (vec3 p)
{
  li = lily(p);
  wat = water(p);
  flo = flower(p);
 return min(li,min(flo,wat));
  }

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
  vec3 f = normalize(tar-ro);
  vec3 l = normalize(cross(vec3(0.,1.,0.),f));
  vec3 u = normalize(cross(f,l));
  return normalize(f + l*uv.x + u*uv.y);
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float sither = hash21(uv);
  vec3 ro = vec3(0.001,8.,-3.),
  p = ro,
  tar = vec3(0.),
  rd = getcam(ro, tar, uv),
  col = vec3(0.);
  
  float d, shad = 0.;
  
  for (float i=0.; i<64.; i++)
  {
      d = SDF(p);
     if (d <0.001)
     {
       shad = i/64.;
       break;
     }
     d *= 0.9+sither*0.05;
     p += d*rd;
  }
  
  if (d==wat)
  {
    col = mix(vec3(0.1,0.2,0.8),vec3(0.7,0.8,0.9),floor((shad)*7.)/7.);
  }
  if (d==li)
  {
     col = mix(vec3(0.1,0.5,0.2),vec3(0.7,0.9,0.8),floor((shad)*15)/15);
  }
  if (d==flo)
  {
     col = mix(vec3(0.7,0.2,0.8),vec3(0.7,0.7,0.8),floor((shad)*8.)/8.)*0.8;
  }
  
  //col = vec3(water(vec3(uv,0.)));
  out_color = vec4(sqrt(col),1.);
}