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
float PI = 3.141592;
float time = fGlobalTime;


vec2 mo(vec2 p, vec2 d)
{
p = abs(p)-d;
if (p.y>p.x) p.xy = p.yx;
return p;
}

vec2 moda (vec2 p, float per)
{
  float a = atan(p.y,p.x);
  float l = length(p);
  a= mod(a-per/2., per) -per/2.;
  return vec2 (cos(a), sin(a))*l;
}
mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a), cos(a));}


float cylH (vec3 p, float r, float h)
{return max(length(p.xz)-r,abs(p.y)-h);}


float cyl (vec2 p, float r)
{return length(p)-r;}


float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}

float g1 = 0.;
float prim1 (vec3 p)
{
  p.y = fract(p.y) -0.5;
  float d = cylH(p.yxz, 0.1, 1.);
  g1 += 0.01/(0.01+d*d);
  return d;
}

float g2 = 0.;
float prim2(vec3 p)
{

  p.xz = moda(p.xz, PI);

  p.x -= 1.;
  float d = cyl(p.xz, 0.1);
  g2 += 0.01/(0.01+d*d);
  return d;
}

float prim3 (vec3 p)
{
  float bounce = 0.05 + exp(-fract(time))*0.5;
  p.xy = mo(p.xy, vec2 (2.));
  p.z += cos(p.x+time);
  p.y += sin(p.x);
  p.z += 1.5;
  p.y = abs(p.y);
  p.y -= 2.;
  return box (p, vec3(1e9, bounce, bounce));
}

float SDF (vec3 p)
{

  float b = prim3(p);
  float per = 5.;
  p.x = mod(p.x-per/2., per)-per/2.;
  p.xz = mo(p.xz, vec2 (1.2));
  p.xz *= rot(time);
  p.xz *= rot(p.y*0.5);
  return min(min (prim1(p), prim2(p)), b);
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv += texture(texNoise, uv+time).rg * 0.09;

  vec3 ro = vec3(0.001+time*5.,0.001, -10.); vec3 p = ro;
  vec3 rd = normalize(vec3(uv,1.));
  float shad = 0.;

  for (float i = 0.; i<64.; i++)
{
  float d = SDF(p);
  if (d<0.001)
{
  shad = i/64.;
  break;
}
p += d*rd*0.5;
}

  vec3 col = vec3(shad)*0.1;
  col += (g1*vec3(0.1,0.5,0.6) + g2 *vec3(0.5,0.1,0.))*0.5;
  out_color = vec4(pow(col, vec3(0.45)),1.);
}