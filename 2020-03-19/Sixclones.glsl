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

#define P 3.14159
#define TP 2.0 * P
#define HP 0.5 * P
#define QP 0.25 * P

#define t fGlobalTime
#define ht 0.5 * t
#define tt 0.1 * t

#define S(a, b, t) smoothstep(a, b, t)

float map01(float n, float stop2, float start2) {
  return (0.5 * n + 0.5) * stop2 + start2;
}

float circleSDF(vec2 uv) {
  return length(uv);
}

float rectSDF(vec2 uv, vec2 s) {
  return max(abs(uv.x / s.x), abs(uv.y / s.y));
}

vec2 rotate2d(vec2 uv, float a) {
  return uv * mat2(cos(a), sin(-a), cos(a), sin(a));
}

float fill(float x, float s) {
  return 1.0 - step(s, x);
}

float fill(float x, float s, float p) {
  p *= 0.01;
  return 1.0 - S(s - p, s + p, x);
}

float stroke(float x, float s, float w, float p) {
  p *= 0.01;
  return clamp(
    S(s - p, s + p, x - 0.5 * w) * S(s + p, s - p, x + 0.5 * w),
    0.0, 1.0
  );
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float n = 8.0;
  vec2 gv = fract(n * uv);
  vec2 id = floor(n * uv);
  
  vec3 color = vec3(0.0);
  
  float offset = mix(
    map01(sin(-t + P * gv.x - cos(ht + P * id.x) - sin(P * gv.y)), QP, HP),
    map01(cos(t + TP * gv.x), 0.0, TP),
    step(0.5, mod(ht, 2.0))
   );
  float np = map01(
    sin(t + P * uv.x + sin(-t + TP * uv.y) + P * gv.x + offset),
    6.0, 10.0 * uv.x + 4.0 + mod(ht, 0.5));
  vec2 size = vec2(
    map01(cos(t + P * uv.x + 0.5 * sin(t + TP * id.x)), 0.5, 2.0),
    map01(sin(t - QP * uv.y + cos(-ht + TP * (uv.x + uv.y))), 0.5, 2.0)
  );
  float rect = rectSDF(rotate2d(uv, ht + cos(t + P * uv.x)), size);
  vec3 pre = vec3(
    0.0,
    map01(cos(t), 15.0, 20.0),
    map01(sin(t), 15.0, 20.0)
  );
  float circ = circleSDF(uv);
  float circf = fill(circ, map01(sin(t + P * uv.x + sin(-t + 5.0 * P * uv.y) + cos(t + P * (id.x - 0.5))), 0.25, 0.75));
  color.r += fill(fract(-t + np * rect), 0.5, 10.0*cos(t + P * gv.x) + 15.0);
  color.g += fill(fract(-t + np * rect), 0.5, 10.0*sin(t + TP * gv.y + sin(-t)) + pre.y);
  color.b += fill(fract(-t + np * rect), 0.5, 10.0*sin(t + cos(-t + TP * uv.x)) + pre.z);
  color *= circf;
  
  out_color = vec4(color, 1.0);
}