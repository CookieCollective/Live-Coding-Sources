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

float plane(vec3 pos)
{
  return pos.y;
}

float map(vec3 pos)
{
  float p = plane(pos);
  
  pos = mod(pos + vec3(5.0), vec3(10.0)) - vec3(5.0);

  return min(length(pos) - 2.0, p);
}

vec3 normal(vec3 pos)
{
  vec2 e = vec2(0.01, 0.0);
  return normalize(vec3(
    map(pos + e.xyy) - map(pos - e.xyy),
    map(pos + e.yxy) - map(pos - e.yxy),
    map(pos + e.yyx) - map(pos - e.yyx)
  ));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 dir = normalize(vec3(uv, 1.0));
  vec3 pos = vec3(cos(fGlobalTime) * 50.0, sin(fGlobalTime * 0.4) * 4.0 + 5.0, -5.0);
  for (int i = 0; i < 64; i++)
  {
    float d = map(pos);
    pos += dir * d;
  }

  vec3 n = normal(pos);
  vec3 light = normalize(vec3(1.0));
  float diffuse = max(dot(n, light), 0.0);

  float fog = exp((-pos.z + 5.0) * 0.1);
  vec3 color = vec3(diffuse)*vec3(0.8,0.9,0.1);
  color = mix(vec3(0.6,0.0,0.4), color, fog);

  out_color = vec4(color, 0.0);
}