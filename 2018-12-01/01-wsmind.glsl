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

vec2 rotate(vec2 uv, float angle)
{
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, s, -s, c) * uv;
}

float tile2(vec2 uv)
{
  uv.x += cos(fGlobalTime);
  //uv.y += sin(fGlobalTime);
  return step(0.5, length(uv));
}

float tile(vec2 uv)
{
  return step(-0.4, uv.x + uv.y) * step(uv.x + uv.y, 0.4);
}

float hash(vec2 uv)
{
  return fract(sin(dot(uv, vec2(12.578, 3.541)) * 577.4357));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  float pulse = exp(-fract(fGlobalTime) * 20.0);
  uv.x += sin(uv.y * 500.0) * 0.4 * pulse;
  
  vec3 color = mix(vec3(0.7, 0.8, 0.4), vec3(0.2, 0.8, 1.0), uv.x + uv.y);

  uv.x += sin(fGlobalTime * 0.2) * 0.5;

  uv *= 15.0 + sin(fGlobalTime * 0.2) * 5.0;
  vec2 index = floor(uv);
  uv = fract(uv) * 2.0 - 1.0;

  float t0 = floor(fGlobalTime);
  float t1 = fract(fGlobalTime);
  float angle = t0 + floor(hash(index) * 100.0) + pow(t1, 10.0);
  angle *= 3.1415926535 / 2.0;
  uv = rotate(uv, angle);
  
  float t = mod(tile(uv) + tile2(uv), 2.0);
  color = mix(color, vec3(1.0), t);

  out_color = vec4(color, 1.0);
}