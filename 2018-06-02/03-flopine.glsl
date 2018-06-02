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

float time = fGlobalTime;

mat2 rot (float a)
{
return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float tiktak(float per)
{
float tik = floor(time) + pow(fract(time), 3.);
tik *= 3. * per;
return tik;
}

vec2 moda (vec2 p, float per)
{
float a = atan(p.y, p.x);
float l = length(p);
a = mod(a-per/2., per)-per/2.;
return vec2 (cos(a),sin(a))*l;
}

vec2 mo (vec2 p, vec2 d)
{
p.x = abs(p.x)-d.x;
p.y = abs(p.y)-d.y;
if (p.y > p.x) p.xy = p.yx;
return p;
}

float stmin(float a, float b, float k, float n)
{
float st = k/n;
float u = b-k;
return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st,2.*st)-st)));
}

float cyl (vec2 p, float r)
{return length(p)-r;}


float odile (vec3 p, float d)
{return dot(p, normalize(sign(p)))-d;}


float helix (vec3 p)
{

p.xz *= rot(p.y*0.8);
p.xz *= rot(time);
p.xz = moda(p.xz, 2.*3.141592/5.);
p.x -= .8;
return cyl(p.xz, .15);
}

float SDF (vec3 p)
{
float per = 10.;
//p.xy *= rot( tiktak(time , 0.5) );
p.xy *= rot(time);
p.xz *= rot(time);
//p.z = mod(p.z-per/2., per)-per/2.;

p.xy = mo(p.xy, vec2(2.));
p.xz = mo(p.xz, vec2(2.));
p.xy = moda(p.xy, 2.*3.141592/8.);

p.x -= 3.;

return stmin(helix(p), odile(p,1.), 0.4, 5.);
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.01,0.01,-15.); vec3 p = ro;
vec3 dir = normalize(vec3(uv,1.));

float shad = 0.;

for (float i = 0.; i< 64.; i++)
{
float d = SDF(p);
if (d<0.001)
{
shad = i/64.;
break;
}
p+= d*dir*0.5;
}

float t = length(ro-p);

vec3 c = vec3(shad);
c = mix(c, vec3(0.1, -length(uv),length(uv)), 1. - exp(-0.001*t*t));
  out_color = vec4(c,1.);
}