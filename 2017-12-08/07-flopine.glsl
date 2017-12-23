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

vec2 moda (vec2 p, float per)
{
float angle = atan(p.y,p.x);
float l = length(p);
angle = mod(angle-per/2., per)-per/2.;
return vec2 (cos(angle), sin(angle))*l;
}

float sphe1 (vec3 p,float r)
{
p.y -= .8;
return length(p)-r;
}

float sphe2 (vec3 p, float r)
{
p.y -= .5;
r += sin(fGlobalTime)*0.1;
return length(p)-r;
}

float cylY (vec3 p, float r, float h)
{
p.xz = moda(p.xz, 2.*3.14/4);
p.x -= .25;
r += p.y*0.05;
p.xz += sin(p.y+fGlobalTime)*0.1;
return max(length(p.xz)-r, abs(p.y)-h);
}

float body (vec3 p)
{
return max(-sphe2(p, 0.5),sphe1(p,0.5));
}

float SDF (vec3 p)
{
float per = 4.;
p.xz = mod (p.xz-per/2., per)-per/2.;
return min(body(p), cylY(p,0.05,1.));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 p = vec3 (0.01,0.01,-6.);
vec3 dir = normalize(vec3(uv,1.));
vec3 color = vec3 (0.);
for (int i=0; i<60; i++)
{
float d = SDF(p);
if (d<0.01)
{
break;
}
p += d*dir;
}
//color = vec3(exp(-distance(p, vec3(0.);
  out_color = vec4 (p,1.);
}