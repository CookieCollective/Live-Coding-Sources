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

float smin(float a, float b, float k)
{
float h = clamp(0.5+0.5*(b-a)/k,0.,1.);
return mix(b,a,h)-k*h*(1.-h);
}

//vec2 (vec2 p, float angle)
//{
//float c = cos(angle);
//float s = sin(angle);
//return vec2 (p * (c,-s,s,c));
//}

vec2 moda (vec2 p, float per)
{
float angle = atan(p.y, p.x);
float l = length(p);
angle = mod(angle-per/2., per)-per/2.;
return vec2(cos(angle),sin(angle))*l;
}

float sphe (vec3 p, float r)
{
p.y-=.7;
return length(p)-r;
}

float cylY (vec3 p, float r, float h)
{
return max(length(p.xz)-r, abs(p.y)-h); 
}

float plane (vec3 p, vec2 uv)
{
vec4 text = texture(texTex4, uv/2.);
p.y +=.5;
p.y+=text.x;
return p.y;
}
float cylX (vec3 p, float r, float h)
{

p.xz = moda(p.xz, 2.*3.14/5.);
p.x -= 0.8;
p.xy += p.z*sin(fGlobalTime);
p.y += 0.3;
r-=p.x*0.2;
return max(length(p.yz)-r, abs(p.x)-h); 
}

float SDF(vec3 p, vec2 uv)
{
//return cylX(p, 0.2, 0.7);
float body = smin(cylY(p,0.3,.5), sphe(p,0.5), 0.4);
float all_body =  smin(body,cylX(p, 0.2, 1.), 0.5);
return min(all_body, plane(p, uv));
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
vec3 p = vec3 (0.01,0.01,-3.);
vec3 dir = normalize(vec3(uv, 1.));
float shad = 0.;
for (int i=0; i<60; i++)
{
float d = SDF(p, uv);
if (d<0.01)
{shad = float(i)/60.;
break;}
p += d*dir;
}

  out_color = vec4(vec3(1-shad),1.);
}