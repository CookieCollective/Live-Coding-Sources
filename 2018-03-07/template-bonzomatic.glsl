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

vec2 rotate(vec2 p, float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c) * p;
}

float noise(vec3 p)
{
  return texture(texNoise, p.xy * 0.01 + p.z * 0.07).r + texture(texNoise, p.xy * 0.6 + p.z * 0.7).r * 1.2;
}

float map(vec3 p)
{
  p.xy = rotate(p.xy, p.z * 0.4);
  return noise(p) * smoothstep(-.4, -1.0, p.y) * smoothstep(-3.0, -1.0, p.y);
}

float map2(vec3 p)
{
  p *= 0.4;
  return cos(p.x) + cos(p.y) + cos(p.z);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 r = vec3(0.0);

  vec3 dir = normalize(vec3(uv, 1.0 - length(uv) * sin(fGlobalTime) * 4.0));
  vec3 pos = vec3(0.0, 0.4, fGlobalTime * 1.0);
  for (int i = 0; i < 50; i++)
  {
    float d = map2(pos) * map(pos);
    pos += dir * 0.4;

    r += d;
  }
  
  //vec3 color = noise(vec3(uv, fGlobalTime));
  vec3 color = r * 0.2 * mix(vec3(0.7, 0.4, 0.2), vec3(0.0, 0.0, 0.8), uv.x + uv.y);

  color += vec3(0.0, 0.0, 0.1);

  out_color = vec4(color, 1.0);
}