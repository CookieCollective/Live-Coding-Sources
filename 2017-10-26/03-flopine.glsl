#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNogozon;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

/*vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}*/
mat2 rotate (vec2 p, float angle)
{
  float c = cos(angle);
float s = sin(angle);
return mat2 (c,-s,s,c);
}

float sphere (vec3 p, float r)
{return length(p)-r;}

float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}


vec2 moda (vec2 p)
{
float angle = atan(p.y,p.x);
float len = length(p.xy);
float period = 2.*3.14/5.;
angle = mod(angle-period/2., period)/period/2.;
return len*vec2(sin(angle),cos(angle));
}


float SDF(vec3 p)
{ 
float period = 5.;
  float rad = 1.;
  vec3 corn = vec3 (0.75);
  p.xy = moda(p.xy);
p = p-sin(fGlobalTime);
p.xz = mod(p.xz-period/2.,period)-period/2.;
  p.xy *= rotate(p.xy, sin(fGlobalTime)); 

  return max(-sphere(p,rad),box(p,corn));
}

vec3 normals (vec3 p)
{
  vec2 eps = vec2(0.01,0.);
  return normalize(vec3 (SDF(p+eps.xyy) - SDF(p-eps.xyy),
SDF(p+eps.yxy) - SDF(p-eps.yxy),
SDF(p+eps.yyx) - SDF(p-eps.yyx))
);
}


float lighting (vec3 norm_p, vec3 l)
{return dot(norm_p,l)*0.5+0.5;}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec3 pos = vec3(0.001,0.001,-3.);
vec3 dir = normalize(vec3(uv,1.-length(uv)));
vec3 light = normalize(vec3(0.1,1.,-1.));
vec3 col = vec3(0.);


  for (int i = 0; i<60; i++)
{
  float d = SDF(pos);
if (d<0.01) 
{
vec3 norm = normals(pos);
col = vec3 (lighting(norm, light))*vec3(0.9,0.2,0.1)*4.;
break;
}
pos += d*dir;
}
  out_color = vec4(col,1.);
}