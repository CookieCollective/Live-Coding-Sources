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
/*
vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}*/

#define ID_SPHERE 1.0
#define ID_BLACK 2.0
#define ID_LIGHT 3.0
#define mmin(v, d, i) (v.x > d ? vec2(d, i) : v)

float sphere(vec3 p, vec3 pos, float id)
{
  vec3 q = normalize(p - pos);
  return length(p - pos) - 1.0; 
}

float cylinder(vec3 p)
{
  return length(p.xz) - 0.3;
}

float modA(inout vec2 p, float n)
{
  float l = length(p);
  float an = 3.141592 * 2.0 / n;
  float a = atan(p.y, p.x);
  float id = floor(a / an);
  a = mod(a, an) - 0.5 * an;
  p = vec2 (cos(a), sin(a)) * l;
  return id;

}

vec2 map(vec3 p)
{
  float sd = 10000.0;
  vec2 v = vec2(cylinder(p), ID_LIGHT);
  for (int i = 0; i < 9; ++i)
  {
    vec3 q = p;
    float id = modA(q.xz, 10.0 + 5.0 * i);
    v = mmin(v, sphere(p, vec3(1.0 + 2.0 * i, 0.0, 0.0), id), ID_SPHERE);
}

  v = mmin(v, sphere(p, vec3(0.0), 1.0), ID_SPHERE);
  return v;
}



vec4 rm(vec3 ro, vec3 rd)
{
  //float d = 10000.0;
  vec3 p = ro;
  float id = ID_BLACK;
  for (int i = 0 ; i < 64 ; ++i)
  {

    vec2 d = map(p);
    if (abs(d.x) < 0.001)
    { 
      id = d.y;
      break;
    }
    else if (d.x > 1000.0)
      break;
    p += rd * d.x * 0.8;
  }
  return vec4(p, id);
}


vec3 grad(vec3 p)
{
  vec2 e = vec2(0.01, 0.0);
  return normalize(vec3(map(p + e.xyy).x - map(p - e.xyy).x, map(p + e.yxy).x - map(p - e.yxy).x, map(p + e.yyx).x - map(p - e.yyx).x));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);


  vec3 ro = vec3(0.0, 0.0 ,-3.0);
  vec3 rd = vec3(uv, 1.0);
  
  vec4 q = rm(ro, rd);
  vec3 p = q.xyz;
  float id = q.w;

  vec3 n = grad(p);
  vec3 color = vec3(exp(-distance(ro, p) * 0.1)); //* (n * 0.5 + 0.5);

  if (id == ID_LIGHT)
    color = vec3(1.0);
  else if (id == ID_SPHERE)
    color *= 0.1 * (n * 0.5 + 0.5);
  out_color = vec4(color, 1.0);

/*
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = clamp( t, 0.0, 1.0 );
  out_color = f + t;*/
}