#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec2 rotate(vec2 p, float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c) * p;
}

float vmax(vec3 p)
{
  return max(max(p.x, p.y), p.z);
}

float cube(vec3 p, vec3 s)
{
  vec3 d = abs(p) - s;
  return length(max(d, 0.0)) + vmax(min(d, 0.0));
}

float tube(vec2 p, float s)
{
  return length(p) - s;
}

float room(vec3 p)
{
  p.xy = rotate(p.xy, fGlobalTime);
  p.xz = rotate(p.xz, fGlobalTime * 0.7);
  return -cube(p, vec3(10.0));
}

float tubes(vec3 p)
{
  p.xy = rotate(p.xy, p.z * sin(fract(fGlobalTime)) * 0.1);
  p.xz = rotate(p.xz, p.z * sin(fract(fGlobalTime * 1.3)) * 0.5);

  p.xy = rotate(p.xy, fGlobalTime * 0.04 + 2.5);
  p.xz = rotate(p.xz, fGlobalTime * 0.2 + 1.3);

  float d = tube(p.xz, 0.1);
  d = min(d, tube(p.xy, 0.1));
  d = min(d, tube(p.yz, 0.1));
  return d;
}

float map(vec3 p)
{
  float d = room(p);
  d = min(d, tubes(p));

  p.xy = rotate(p.xy, p.z);

  p.xy = rotate(p.xy, fGlobalTime * 2.0);
  p.xz = rotate(p.xz, fGlobalTime * 2.8);

  d = min(d, cube(p, vec3(1.0)));

  return d;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy),
    map(p + e.yxy) - map(p - e.yxy),
    map(p + e.yyx) - map(p - e.yyx)
  ));
}

float light(float d)
{
  return 3.0 / (d * d + 1.0);
}

vec3 tonemap(vec3 c)
{
  c = c / (c + 1.0);
  return pow(c, vec3(1.0 / 2.2));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float beat = exp(-fract(fGlobalTime) * 20.0);
  uv.x += sin(uv.y * 500.0) * beat;

  vec3 pos = vec3(0.0, 0.0, -4.0);
  vec3 dir = normalize(vec3(uv, 1.0 - length(uv) * 0.8));

  for (int i = 0; i < 64; i++)
  {
    float d = map(pos);
    if (d < 0.001) break;
    pos += dir * d;
  }

  vec3 n = normal(pos);
  float diffuse = dot(n, normalize(vec3(1.0))) * 0.5 + 0.5;

  vec3 tubeLight = light(tubes(pos)) * vec3(30.0 * exp(-fract(fGlobalTime) * 10.0), 0.0, 40.0);

  vec3 radiance = vec3(diffuse) * vec3(0.2, 0.0, 20.0) * 4.0 + tubeLight;
  out_color = vec4(tonemap(radiance) * (1.0 / length(uv * 10.0)), 1.0);
}