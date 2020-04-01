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

mat2 rot (float a)
{return mat2 (cos(a),sin(a),-sin(a),cos(a));}

void mo (inout vec2 p, vec2 d)
{
  p = abs(p)-d;
  if (p.y>p.x) p = p.yx;
}

void moda (inout vec2 p, float rep)
{
  float per = TAU/rep;
  float a = atan(p.y,p.x);
  float l = length(p);
  a = mod(a,per)-per*0.5;
  p = vec2(cos(a),sin(a))*l;
}

float prim1 (vec3 p,float size)
{
  p *= size;
  p.yz *= rot(time);
  //p.xz *= rot(time);
  float c = length(p.xz) -1.;
  mo(p.xz,vec2(0.9));
  moda(p.xz, 3.);
  mo(p.yz,vec2(0.2));
  moda(p.xy, 8.);
  mo(p.xy,vec2(0.1));
  return max(-c,dot(p,normalize(vec3(0.5,.5,3.)))) / (size);
}

float fractal (vec3 p)
{
  float s = 1.;
  float d = prim1(p,s);
  for (int i=1; i<4; i++)
  {
    float ratio =float( i)/3.;
    s -= 0.3;
    p.xz *= rot(time*ratio);
    d = min(d, prim1(p,s));
   }
   return d;
}

float g1 = 0.;
float SDF (vec3 p)
{
  float sphe = length(p)-(2.+texture(texNoise, p.xy*5).x);
  g1 += 0.01/(0.01+sphe*sphe);
  return max(-(length(p+vec3(0.,0.,12.))-3.),min(sphe,fractal(p)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001,-12.),
  rd = normalize(vec3(uv,1.)),
  col = vec3(0.),
  p = ro;
  
  float shad = 0.;
  bool hit = false;
  
  for (float i=0.; i<64.; i++)
  {
    float d = SDF(p);
    if (d<0.001)
    {
      hit = true;
      shad = i/64.;
      break;
    }
    p += d*rd*0.8;
 }
  if (hit)
  
  {
    col = vec3(1.-shad); 
  col += g1*vec3(.8,.1,0.9)*0.7;
  }
  
  
  out_color = vec4(sqrt(col),1.);
}