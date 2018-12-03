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

float hash(vec2 uv)
{
  return fract(sin(dot(uv, vec2(12.9898, 78.5354))) * 43758.5354);
}

vec2 rotate(vec2 uv, float angle)
{
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, s, -s, c) * uv;
}

float vmax(vec3 v)
{
  return max(max(v.x, v.y), v.z);
}

float box(vec3 pos, vec3 size)
{
  vec3 diff = abs(pos) - size;
  return length(max(diff, 0.0)) + vmax(min(diff, 0.0));
}

float map(vec3 pos)
{
  //return 5.0 - length(pos);
  return max(max(-box(pos, vec3(3.0)), -box(pos, vec3(4.0, 1.0 + sin(fGlobalTime) + 1.0, 3.0))), -box(pos, vec3(2.0, sin(fGlobalTime) + 1.0, 4.0)));
}

bool traceRay(inout vec3 pos, vec3 dir)
{
  for (int i = 0; i < 64; i++)
  {
    float d = map(pos);
    if (d < 0.001)
      return true;
    pos += dir * d;
  }
  return false;
}

vec3 computeNormal(vec3 pos)
{
  vec2 e = vec2(0.01, 0.0);
  return normalize(vec3(
    map(pos + e.xyy) - map(pos - e.xyy),
    map(pos + e.yxy) - map(pos - e.yxy),
    map(pos + e.yyx) - map(pos - e.yyx)
  ));
}

vec3 computeEmissive(vec3 pos)
{
  return step(3.9, pos.x) * vec3(1.0, 0.4, 0.0) * 4.0 + step(pos.x, -3.9) * vec3(0.6, 0.8, 0.9) * 4.0;
}

vec3 computeAlbedo(vec3 pos)
{
  return vec3(0.8);
}

vec3 cosineSampleHemisphere(vec2 rng)
{
  float radius = sqrt(rng.x);
  float angle = 2.0 * 3.1415926535 * rng.y;
  return vec3(radius * cos(angle), radius * sin(angle), sqrt(1.0 - rng.x));
}

vec3 samplePath(vec2 rng, vec3 pos, vec3 dir)
{
  vec3 radiance = vec3(0.0);
  vec3 pathTransmittance = vec3(1.0);

  for (int i = 0; i < 4; i++)
  {
    if (!traceRay(pos, dir))
      break;
    
    vec3 normal = computeNormal(pos);
    vec3 emissive = computeEmissive(pos);
    vec3 albedo = computeAlbedo(pos);

    radiance += pathTransmittance * emissive;
    pathTransmittance *= albedo;

    vec2 off = vec2(float(i));
    dir = cosineSampleHemisphere(vec2(hash(rng + off), hash(rng + off + 1.0)));
    if (dot(dir, normal) < 0.0)
      dir = -dir;
    pos += dir * 0.2;
  }

  return radiance;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 pos = vec3(0.0, 0.0, 0.0);
  vec3 dir = normalize(vec3(uv, 0.4));

  dir.xy = rotate(dir.xy, fGlobalTime * 0.4);
  dir.xz = rotate(dir.xz, fGlobalTime * 0.3);

  vec3 radiance = vec3(0.0);
  for (int i = 0; i < 4; i++)
  {
    vec2 rng = vec2(hash(uv), hash(uv + 1.0)) + float(i);
    radiance += samplePath(rng, pos, dir);
  }
  radiance /= 4.0;

  vec3 color = radiance;
  color /= (color + 1.0);
  color = pow(color, vec3(1.0 / 2.2));

  out_color = vec4(color, 0.0);
}