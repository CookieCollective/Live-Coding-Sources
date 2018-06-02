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

#define PI 3.14159

float beate(float f)
{
  return f + sin(mod(f,1.) * PI);
}

float rep(float f, float r)
{
return mod(f + r/2. ,r) - r/2.;
}

mat2 rot(float a)
{
float c  = cos(a); float s = sin(a);

return mat2(c,-s,s,c);
}


float map(vec3 pos)
{

pos.z += beate(fGlobalTime * 1.75) * 2.;

pos.xy *= rot(pos.z * .1);
pos.x += 2.;

pos.x = rep(pos.x, 4.);
pos.y = rep(pos.y, 2.);
pos.z = rep(pos.z, 2.);



return length(pos) - 1.;
}

vec3 norm(vec3 p)
{
vec2 e = vec2(.01,0.);
return vec3(
  map(p + e.xyy) - map(p - e.xyy),
  map(p + e.yxy) - map(p - e.yxy),
  map(p + e.yyx) - map(p - e.yyx)
);
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv *= rot(fGlobalTime);
float f = uv.x;

  vec3 ro = vec3(0.,0.,-5.);
vec3 rd = normalize(vec3(uv,1.));
vec3 cp = ro;

float s = 0.;
for(;s < 1.; s += 1. / 128.)
{
float cd = map(cp);
if(cd < .01)
{
break;
}
cp += rd * cd * .5;

}


  f = 1. - s;

  float li = dot(normalize( cp - ro),norm(cp));
  li = clamp(li,0.,1.);
  //f = distance(f,uv.y);
  //f = step(f, .005);
  
  
out_color = mix(vec4(0.), vec4(sin(cp.z),cos(.0 * cp.z),.5,1.),f);
}