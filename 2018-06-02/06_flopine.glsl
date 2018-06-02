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
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float tiktak (float per)
{
float tik = floor(time) + pow(fract(time), 3.);
tik *= 3.*per;
return tik;
}

float g = 0.;

float megabass ()
{
return texture (texFFT, 0.5).r;
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
return a+b*cos(c*(t+d));
}

float stmin(float a, float b, float k, float n)
{
float st = k/n;
float u = b-k;
return min(min(a,b), 0.5 * (u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float sphe (vec3 p, float r)
{return length(p)-r;}

float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}

float prim1 (vec3 p)
{
p.xz *= rot(time);
p.xy *= rot(time);
return max(-sphe(p,1.3 +( sin(time)*0.5)), box(p,vec3(1.)) );
}


float fractal (vec3 p, int STP)
{
float c = prim1(p);
for (int i = 0; i<STP; i++)
{
p = abs(p);
p.xz *= rot(3.141592/4.);
p.xy *= rot(3.141592/3.);
p.x -= 2. + exp(-fract(time)+1.);
p.z += sin(p.x*0.2);
c = stmin(c, prim1(p),0.5, 3.);
}
return c;
}

float SDF (vec3 p)
{
p.xy *= rot(tiktak(0.5));
float f = fractal(p, 4);
g += f*0.5;
return f;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001, -30.+megabass()); vec3 p = ro;
vec3 dir = normalize(vec3(uv,1.));

float shad = 0.;
for (float i=0.; i<64.; i++)
{
float d = SDF(p);
if (d<0.001)
{
shad = i/64.;
break;
}
p+= d*dir*0.8;
}
float t = length(ro-p);

vec3 pal = palette(length(uv),
vec3(0.5),
vec3(0.5),
vec3(5.),
vec3(0.,0.8,0.8));

vec3 c = (vec3(shad)*2.)*vec3(0.5, p.z, p.z);
c = mix(c, pal, 1.-exp(-0.001*t*t));
  out_color = vec4 (c,1.);
}