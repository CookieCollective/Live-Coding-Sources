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

vec2 rotate(vec2 p, float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c) * p;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float beat = exp(-fract(fGlobalTime) * 7.0);
  
  uv *= pow(length(uv), sin(fGlobalTime) * 2.0 + 1.2);
  uv.x += sin(uv.y * 540.0) * beat * 0.1;

  uv = rotate(uv, fGlobalTime * 0.2);

  vec3 color = vec3(0.0);
  for (int i = 0; i < 200; i++)
  {
    float r = fract(sin(i * 1.478946));
    vec2 pos = vec2(cos(i + fGlobalTime * 0.8 * r), sin(i + fGlobalTime * 2.0)) * r;
    float d = smoothstep(0.04 * r, 0.0, length(pos - uv)) - smoothstep(0.01 * r, 0.0, length(pos - uv));
    color += d * vec3(1.0, r * 0.2, 0.0) * 10.0;
  }


  float b = pow(dot(normalize(abs(uv)), abs(vec2(cos(fGlobalTime), sin(fGlobalTime)))), 1040.0);
  color += clamp(b, 0.0, 1.0) * vec3(0.4, 0.8, 0.0) * 10.0;

  color += texture(texNogozon, (uv + vec2(fGlobalTime * 0.1)) * 1.4).rgb * 0.02;

  color *= beat * (1.0 - length(uv) * 0.4);

  color = color / (1.0 + color);
  color = pow(color, vec3(1.0 / 2.2));

  out_color = vec4(color, 1.0);
}