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

vec2 rotate(vec2 uv, float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c) * uv;
}

float circle(vec2 uv, float r, float w, float m, float t)
{
  float l = length(uv);
  float a = atan(uv.x, uv.y);
  return smoothstep(r, r + 0.01, l) * smoothstep(r + w, r + w - 0.01, l) * step(mod(a + t, m), m * 0.5);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float pulse = exp(-fract(fGlobalTime * 0.4));
  
  uv = rotate(uv, fGlobalTime * length(uv) * sin(fGlobalTime) * 0.01);
  uv *= 0.5 / pulse;

  uv.y += sin(uv.x * 20.0 + fGlobalTime * 5.0) * 0.02;

  vec3 color = uv.xyx * circle(uv, 0.3, 0.02, 0.9, fGlobalTime);
  color += sin(uv.x * 200.0) * circle(uv, 0.2, 0.01, 0.9, fGlobalTime);

  color += mix(vec3(0.6, 0.2, 0.7), vec3(1.0, 0.4, 0.7), (dot(uv, vec2(cos(fGlobalTime), sin(fGlobalTime))))) * vec3(0.7, 0.2, 0.1);
  color *= fract(uv.y * 3.0 + fGlobalTime) * 0.1;
  color += -0.2 - exp(-fract(fGlobalTime * 0.8) * 10.0) * sin(uv.y * 800.0 + fGlobalTime * 400.0) * 4.0;

  for (int i = 0; i < 16; i++)
    color += fract(uv.y * 50) * vec3(float(i), 0.6, 0.2) * circle(uv, sin(float(i) * 0.7) * 0.4, sin(float(i) * exp(-fract(fGlobalTime * 1.0))) * 0.1, sin(float(i)), fGlobalTime * sin(float(i) * 30.0) * 2.0);

  color += length(uv) * vec3(0.1, 0.4, 0.7) * 3.0;

  color *= 2.0;
  color /= color + 1.0;
  
  color = sqrt(color);

  out_color = vec4(color, 1.0);
}