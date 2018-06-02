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

float bass;

float megabass()
{
  float b = 0.0;
  for (int i = 0; i < 10; i++)
  {
    b = max(texelFetch(texFFTIntegrated, i, 0).x, b);
  }
  return b * 8.0;
}

mat2 rot(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

float dur(vec3 p)
{
  p.xy *= rot(p.z * 0.1);
  p.z += 0.1 * texture(texNoise, p.xy).x;
  return cos(p.x) + cos(p.y) + cos(p.z);
}

vec3 rm(vec3 ro, vec3 rd, out float st, int it)
{
  st = 1.0;
  vec3 p = ro;
  for (int i = 0; i < it; ++i)  
  {
    float d = dur(p);
    if (abs(d) < 0.01)
    {
      st = float(st) /float(it);
      break;
    }
    p += rd * d * 0.8;
  }
  return p;
}

vec3 shade(vec3 ro, vec3 p, vec3 n, float st)
{
  float off = p.x + p.y  + p.z;
  vec3 c = vec3(0.5 + 0.5 * cos(bass + off), 0.5 + 0.5 * sin(bass + off), 1.0);

  return vec3(exp(-distance(ro, p) * 0.1)) * c * (1.0 - st);
}

vec3 grad(vec3 p)
{
  vec2 eps = vec2(0.01, 0.0);
  return normalize(
    vec3(dur(p + eps.xyy) - dur(p - eps.xyy), 
        dur(p + eps.yxy) - dur(p - eps.yxy),
      dur(p + eps.yyx) - dur(p - eps.yyx))
  );
}

void main(void)
{
  bass = megabass();
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float st;
  vec3 ro = vec3(0.0, 0.0, bass);
  vec3 rd = normalize(vec3(uv, 0.4 - length(uv)));

  vec3 p = rm(ro, rd, st, 32);
  vec3 n = grad(p);
  vec3 color = shade(ro, p, n, st);

  vec3 rd2 = reflect(rd, n);
  vec3 ro2 = p + rd2 * 0.1;
  float st2;
  
  vec3 p2 = rm(ro2, rd2, st2, 8);
  vec3 n2 = grad(p2);
  
  color = mix(color, shade(ro, p2, n2, st2), 0.4);

  color = pow(color, vec3(1.0 / 2.2));
  out_color = vec4(color, 1.0);
}