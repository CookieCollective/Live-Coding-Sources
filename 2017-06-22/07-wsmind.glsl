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

float circle(vec2 uv, float r, float w, float f, float speed)
{
  float a = atan(uv.y, uv.x) + fGlobalTime * speed;
  float d = length(uv);
  float e = step(mod(a * f, 6.2832), 0.4);
  return e * smoothstep(r, r + 0.01, d) * smoothstep(r + w, r + w - 0.01, d);
}

vec3 plop(vec2 uv)
{
  return dot(uv, vec2(0.707, 0.707)) * vec3(cos(uv.x), cos(uv.y), sin(uv.x));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float s = circle(uv, 0.3, 0.05, 40.0, 0.3);
  s += circle(uv, 0.2, 0.01, 10.0, 1.0 + texture(texFFT, 0.001).r * 100.0);

  for (int i = 0; i < 10; i++)
  {
    s += circle(uv, 0.4 + 0.04 * float(i), 0.02, float(i), float(i) * 0.01);
  }

  uv.y += sin(uv.x + fGlobalTime * 0.4) * 0.1;

  s += circle(uv, 0.04, 0.5, 3.0, 0.3);

  for (int i = 0; i < 5; i++)
  {
    s += clamp(length(uv - vec2(sin(uv.y * 100.0 + fGlobalTime * 4.0), uv.y)), 0.0, 0.1);
  }

  uv = abs(uv);

  for (int i = 0; i < 20; i++)
  {
    s += 0.2 * (1.0 - step(0.9, abs((uv.y + float(i) * 0.2) * 20.0 - 10.0 - sin(uv.x * 10.0 + fGlobalTime * 2.0))));
  }

  vec3 color = vec3(s) + plop(uv);
  color = color / (color + 1.0);
  color += texture(texPegasus, uv * 0.5 + 0.5).rgb * 0.4 * circle(uv, 0.2, 0.4, 2.0, 0.2);
  color = pow(color, vec3(1.0 / 2.2));
  color *= pow(color, vec3(length(uv * 20.0)));

  out_color = vec4(color, 1.0);
}