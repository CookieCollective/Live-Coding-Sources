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

vec2 moda (vec2 p, float per)
{
float a= atan(p.y, p.x);
float l = length(p);
a = mod(a-per/2., per) -per/2.;
return vec2(cos(a),sin(a))*l;
}

vec2 mo (vec2 p, vec2 d)
{
p = abs(p)-d;
if (p.y >p.x) p.xy = p.yx;
return p;
}

mat2 rot(float a)
{return mat2 (cos(a),sin(a),-sin(a), cos(a));}

float stmin(float a, float b, float k, float n)
{
float st = k/n;
float u = b-k;
return min(min(a,b),0.5 * (u+a+abs(mod(u-a+st, 2.*st)-st)));
}

float sphe (vec3 p, float r)
{return length(p)-r;}

float od (vec3 p, float d)
{
return dot(p, normalize(sign(p)))-d;
}

float cyl (vec2 p, float r)
{return length(p)-r;}

float g1 = 0.;
float prim1 (vec3 p)
{
float d = sphe(p, 0.8);
g1 += 0.01/(0.01+d*d);
return d;
}

float prim2 (vec3 p)
{
float per = 5.;
vec3 pp = p;
p.y = mod(p.y-per/2., per) -per/2.;
float o = min(prim1(p),max(-sphe(p, 1.2),od(p, 1.)));


p = pp;
p.xz *= rot(time*0.7);
p.xz *= rot(p.y*0.5);
p.xz = moda(p.xz, (2.*3.14)/4.);
p.x -= 1.3;


return stmin(o, cyl(p.xz, 0.15), 0.5, 4.);
}


vec2 frame_size =  vec2 (10., 7.);

float prim3 (vec3 p)
{
p.xy = mo(p.xy,frame_size);
return prim2(p);
}


float g2 = 0.;
float in_frame(vec3 p)
{
p.xy +=texture(texNoise, p.xy).rg * 0.2;
p.z +=sin(p.y);
p.x += cos(p.z + time);
  p.x = abs(p.x + p.y);

p.x = fract(p.x)-0.5;
float d = cyl(p.xz, 0.15);
g2 += 0.01/(0.01+d*d);
return d;
}

float prim4 (vec3 p)
{
if (abs(p.x) <= frame_size.x && abs(p.y) <= frame_size.y) return in_frame(p);
}

float SDF (vec3 p)
{
  return min(prim3(p), prim4(p));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001, -20.); vec3 p = ro;
  vec3 rd = normalize(vec3(uv, 1.));

  float shad = 0.;

  for (float i=0.; i<64.; i++)
{
  float d = SDF(p);
  if (d<0.01)
{
shad = i/64.;
break;
}

p += d*rd*0.7;
}

  vec3 col = vec3(shad);
col += g1*vec3(0.,0.5,0.2) + g2 *vec3(0.1,0.3,0.3);

  out_color = vec4(col,1.);
}