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

float bass()
{
  float f = 0.0;
  for (int i = 0 ; i < 64; ++i)
{
    f += texture(texFFTIntegrated, float(i)/1024.0).x;
}
  return f;
}

float bass2()
{
  float f = 0.0;
  for (int i = 0 ; i < 32; ++i)
{
    f += texture(texFFT, float(i)/1024.0).x;
}
  return f;
}

int id = 0;

float b = 0.0;
float map(vec3 p)
{
  vec3 u = vec3(0.0, 2.0, 2.0 + fGlobalTime);
  vec3 o = p - u;
   vec2 t = vec2(atan(p.y, p.x), asin(p.z)) + 0.05 * b;
  float v = texture(texNoise, t).x;
  float d = length(p - u) - 0.5 + 0.6 * v;
  float d2 = cos(p.x) + sin(p.y) +cos(p.z) + 0.2 * bass2() * cos(p.y * 20.0);
  if (d2 < d)
    id = 1;
  return min(d,d2);
}

float occ = 1.0;

vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for (int i = 0; i < 64; ++i)
  {
    float d = map(p);
    if (abs(d) < 0.01)
    {
      occ = i / 64.0;
      break;
    }
    p += rd * d * 0.8;
  }
    return p;
}

void main(void)
{
 b = bass();
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 2.0, fGlobalTime);
  vec3 rd = normalize(vec3(uv, 1.0));

  vec3 p = rm(ro, rd);

   
  vec3 color = vec3(exp(-distance(ro, p) * 0.1));

  vec3 u = vec3(0.0, 2.0, 200.0 * b);
  vec3 o = p - u;
   vec2 t = vec2(atan(p.y, p.x), asin(p.z)) + 0.1 * b;
  vec3 vcolor = texture(texChecker, t).rgb;
vec3 v2color = texture(texTex4, t).rgb;
  //if (id == 1)
  //  color *= vcolor * (1.0 - occ);
  // else 
  color *= (vcolor * 0.7  +  0.5 * v2color) * (1.0 - occ);

  out_color = vec4(color, 1.0);
}