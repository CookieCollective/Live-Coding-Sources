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
   float b = 0.0;
  for (int i = 0; i < 8; ++i)
  {
    b = max(b, texelFetch(texFFTIntegrated, i, 0).x);
  }
  return b;
}


float bass2()
{
   float b = 0.0;
  for (int i = 0; i < 8; ++i)
  {
    b = max(b, texelFetch(texFFT, i, 0).x);
  }
  return b;
}

mat2 rot2d(float a )
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, -s, s, c);
}

float megabass =0.0;
float megabass2 =0.0;

float map(vec3  p)
{
  p.xy = p.xy * rot2d(p.z * 0.2);
  return cos(p.x) + sin(p.y + 1.0) + cos(p.z) + (0.05 + 0.2 * megabass2) * cos(p.y + p.z * 20.0) + 0.1 * cos(p.y);
}

vec3 grad(vec3 p)
{
  vec2 eps = vec2(0.001, 0.0);
  return normalize(vec3(map(p + eps.xyy) - map(p - eps.xyy),
                   map(p + eps.yxy) - map(p - eps.yxy),
                   map(p + eps.yyx) - map(p - eps.yyx)));
}

vec3 rm(vec3 ro, vec3 rd, out float st)
{
    vec3 p = ro;
  for (int i = 0; i < 64; ++i)
  {
    float d = map(p);
    if (abs(d) < 0.001)
    {
      st = i;
      break;
    }
    p += d * rd * 0.8;
  }
return p;
}

vec3 shade(vec3 p, vec3 ro, float st, vec3 n)
{
  vec3 color = exp(-distance(p, ro)* 0.1) * (n * 0.5 + 0.5) * pow((float(st) / 64.0), 0.5);
  color = mix(vec3(0.1, 0.7, 1.0), color, exp(-distance(p, ro)* 0.1));
  return color;
}

void main(void)
{
    megabass = bass();
    megabass2 = bass2();

  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 0.0, megabass * 8.0);
  vec3 rd = normalize(vec3(uv, 0.7 - length(uv)));
  rd.xy *= rot2d(megabass);

  
  float st = 0.0;
  vec3 p = rm(ro, rd, st);
  

  vec3 n = grad(p);
  vec3 color = shade(p, ro, st, n);

  
  vec3 rd2 = reflect(rd, n);
  vec3 ro2 = p + 0.1 * rd2;

  vec3 p2 = rm(ro2, rd2, st);
  vec3 n2 =  grad(p2);
  
  vec3 color2 =  shade(p2, ro, st, n2);
  color = mix(color, color2, 0.5);

  out_color = vec4(color, 1.0);
}