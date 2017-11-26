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
mat2 rot(float a)
{
float c = cos(a);float s = sin(a);
return mat2(c,-s,s,c);
}

float rep(float p, float r)
{
return mod(p + r/2,r) - r/2;
}

float map(vec3 p)
{
vec3 p2 = p;
 p2.yz *= rot( p2.z * .00005 + sin(p2.z *-.15- fGlobalTime * .2) * .1);

float f1 = 4-max(distance(p2.x,0),distance(p2.y,0));//distance(p,vec3(0,0,0)) -1;
float f3 = 4-max(distance(p2.x,0),distance(p2.y,0));
p2.z += fGlobalTime * 10;
vec3 p3 = p2;
p3.x = abs(p3.x);
float f5 = (2 + sin(p3.z * .3)) - distance(p3.xy, vec2(4,0));
p2.z = rep(p2.z, 10);  
p2.x = abs(p2.x );
float f2 = distance(p2, vec3(0,-1 + abs(p .x),0)) - 1;
float f4 = distance(p2.yz , vec2(-5,0)) - 1.5;
f1 = max(f1,f5);
return min(min(f1,f2),f4);
}

vec3 norm(vec3 p)
{
vec2 e = vec2(.1,0);
return normalize(vec3(
map(p - e.xyy) - map(p + e.xyy),
map(p - e.yxy) - map(p + e.yxy),
map(p - e.yyx) - map(p + e.yyx)
));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec3 ro = vec3(0,1,-5);
vec3 rd = normalize(vec3(uv.xy,1));
  float ST = 128;
  float st = 0.;
float cd = 0;
vec3 cp = ro;

for(;st < ST;st++)
{
cd = map(cp);
if(cd < .001)
break;
cp += cd * rd * .5;
}

vec3 light = vec3(0,0,25 + sin(fGlobalTime) * 10);
vec3 lDir = normalize(cp - light);
float lum = clamp(dot(norm(cp),lDir),0,1);
float dist = distance(ro,cp);
float f= dist / 50;
  out_color = vec4(lum);
}