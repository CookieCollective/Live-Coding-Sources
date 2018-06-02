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
  for (int i = 0; i < 16; i++)
    b = max(texelFetch(texFFTIntegrated, i, 0).x, b);
  return b;
}

float cyl(vec3 p, float r, float h)
{
  return max(length(p.xz) - r, abs(p.y) - h);
}

float bou(vec3 p)
{
  float d = cyl(p, 0.5, 0.5);
  return min(d, cyl(p - vec3(0.0, 0.8, 0.0), 0.2, 0.3));
}

mat2 rot(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

int prout;

float map(vec3 p)
{
  vec3 per = vec3(3.0);
  ivec3 id = ivec3(p/per);
  vec3 q = mod(p, per) - 0.5 * per;
  q .y += 0.5 * sin(float(p.z));
  q.xy *= rot(float(id.x * 0.2561 + id.y + id.z) + bass);
  q.yz *= rot(float(id.x * 0.2561 + id.y + id.z) + bass);

  prout = id.x + id.y +id.z;
  float d = bou(q); 

  return d;
}

vec3 grad(vec3 p)
{
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(map(p+e.xyy) - map(p-e.xyy), map(p+e.yxy) - map(p-e.yxy), map(p+e.yyx) - map(p-e.yyx)));
}

vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
   for (int i = 0; i < 364; ++i)
    {
    float d = map(p);
    if (abs(d) < 0.01)
    {
      break;
    }
    p += rd * 0.9 * d;
  }
  return p;
}

vec3 shade(vec3 p,  vec3 ro, vec3 n)
{
  return vec3(exp(-distance(ro, p) * 0.1)) * vec3(cos(float(prout) + bass * 0.1), sin(float(prout) + bass * 0.1), 1.0); //* (n * 0.5 + 0.5);
}

void main(void)
{
  bass = megabass();
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 0.0, bass * 5.0);
  vec3 rd = normalize(vec3(uv, normalize(length(uv)) - 0.6));

  rd.xz *= rot(0.1 * bass);

  vec3 p = rm(ro, rd);
  vec3 n = grad(p);
  vec3 color = shade(p, ro, n);

  vec3 rd2 = reflect(rd, n);
  vec3 ro2 = p + rd * 0.01;

  vec3 p2 = rm(ro2, rd2);
  vec3 n2 = grad(p2); 

  color = mix(color, shade(p2, ro, n2), 0.9);
  color = pow(color, vec3(1.0 / 2.2));
  out_color = vec4(color, 1.0);
}