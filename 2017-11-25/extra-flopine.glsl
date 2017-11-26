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

mat2 rot (float angle)
{ float c = cos(angle);
  float s = sin (angle);
return mat2 (c,-s,s,c);
}

float sphe (vec3 pos, float r)
{
  return length (pos) - r;
}

float cylinder (vec2 pos, float r)
{
  return length (pos) - r;
}

float box (vec3 p, vec3 c)
{
vec3 d=abs(p) - c;
return min(max(d.x,max(d.y,d.z)),0.0)+length(max(d,0.));
}

vec2 moda (vec2 p)
{
float angle = atan(p.y,p.x);
float l = length(p);
float period = 2.*3.1459/3.;

angle = mod(angle-period/2., period)-period/2.;
return vec2(cos(angle)*l,sin(angle)*l);
}


float map (vec3 p)
{
float period = 2.;
p.xz *= rot(sin(fGlobalTime));

p.yz = moda(p.yz);
p = mod(p-period/2., p)-period/2.;
  return max(-sphe(p,1.),box(p,vec3(0.8)));
//return box(p,vec3 (0.8));
}


vec3 nor (vec3 p)
{
vec2 eps = vec2(0.01,0.);
return normalize(vec3(
map(p+eps.xyy) - map(p-eps.xyy),
map(p+eps.yxy) - map(p-eps.yxy),
map(p+eps.yyx) - map(p-eps.yyx)
));
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec3 pos = vec3 (0.001,0.2,-20.);
vec3 dir = normalize(vec3(uv*.5,1.));
vec3 l  = normalize(vec3(0.,0.,-3.));
vec3 color = vec3(0.);


  for (int i = 0; i<80;i++)
{
float d = map(pos);
if (d<0.01)
{vec3 norm = nor(pos);
color = vec3(dot(norm,l));
break;
}
d *= 0.5;
pos += d*dir;
}
  out_color = vec4(color,1.);
}