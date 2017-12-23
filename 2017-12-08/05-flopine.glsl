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

vec2 moda(vec2 p, float per)
{
float angle = atan(p.y,p.x);
float l = length(p);
angle = mod(angle-per/2., per)-per/2.;
return vec2 (cos(angle), sin(angle))*l;
}

vec2 rot (vec2 p, float angle)
{
float c = cos(angle);
float s = sin(angle);
return mat2(c,-s,s,c)*p;
}
 
float sphe (vec3 p, float r)
{return length(p)-r;}

float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}

float SDF (vec3 p)
{
float per = 1.1;
p.xz = moda(p.xz, 2.*3.14/5.);
p.x -= 13.; 
p.z = mod(p.z-per/2., per)-per/2.;
p.yz = rot(p.yz, fGlobalTime);
p.xz = rot(p.xz, sin(fGlobalTime));
//p.y += .8;
  return max (-sphe(p, 0.4), box(p, vec3(0.3)));
}

vec3 norms (vec3 p)
{
  vec2 eps = vec2 (0.01,0.0);
  return normalize(vec3(SDF(p+eps.xyy)-SDF(p-eps.xyy),  
                      SDF(p+eps.yxy)-SDF(p-eps.yxy),
                      SDF(p+eps.yyx)-SDF(p-eps.yyx)
                    )
                  ); 
}

float lighting (vec3 n, vec3 l)
{
return dot(n,l)*0.5+0.5;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

vec3 p = vec3 (0.01,0.01,-6.);
vec3 dir = normalize(vec3(uv*0.7, 1.));
float shad = 0.;
vec3 color = vec3(0.);
vec3 light = vec3 (3.,1.,-3.);


for (int i = 0; i< 100; i++)
{
float d = SDF(p);
if (d<0.01)
{
vec3 norm = norms(p);
color = vec3 (lighting(norm, light))*vec3(0.4,0.4,0.1);
break;
}
d *= 0.7;
p += d*dir;
}

  out_color = vec4(color,1.);
}