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

#define PI 3.141592

float h(vec2 uv)
{
  float a = acos(cos(clamp(mod((atan(uv.x, -uv.y)+PI)*10., 14*PI)-2*PI, 0., 2*PI)))/PI;
  return smoothstep(0.01, 0.015, abs(length(uv)-(.4+a*.2)));
}

float e(vec2 uv, vec2 p)
{
  uv += p;
  uv /= vec2(.2, .1);
  float d = smoothstep(0.6, 0.7, length(uv));
  
  uv += vec2(.25, -.25);

  d += smoothstep(0.2, 0.15, length(uv));

  uv += vec2(-.2, .2);

  d += smoothstep(0.1, 0.05, length(uv));

  return d;
}

float n(vec2 uv)
{
  return smoothstep(0.04, 0.05, abs(uv.x)+mix(-uv.y, 1., smoothstep(-0.01, 0.2, uv.y)));
}

float m(vec2 uv, vec2 p)
{
  uv += p;

  float h = 0.01;

  float d = mix(1., smoothstep(0.002, 0.007, abs(uv.y-(abs(uv.x)*.1+cos(uv.x*70.)*h))), step(-0.08, uv.x)*(1.-step(0.08, uv.x)));

  d *= mix(1., smoothstep(0.002, 0.007, abs(uv.x)), step(h, uv.y)*(1.-step(p.y, uv.y)));

  return d;
}

vec2 rot(vec2 uv, float a)
{
  return mat2(cos(a), sin(a), -sin(a), cos(a))*uv;
}

float s(vec2 uv, vec2 p, float r, float inv)
{
  uv += p;

  uv = rot(uv, r*(2.*inv-1.));
  
  float f1 = mix(step(.05, uv.x), 1.-step(-0.05, uv.x), inv);
  float f2 = mix(1.-step(0.25, uv.x), step(-0.25, uv.x), inv);
  return mix(1., smoothstep(0.002, 0.007, abs(uv.y+uv.x*uv.x)), f1*f2);
}

float MEGABASS()
{
  float m = 0.;
  for(int i = 0; i < 64; ++i)
  m = max(m, texture(texFFTSmoothed, i/1024).r);
  
  return m;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= .5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float bass = MEGABASS();

    vec3 c = vec3(1.);

  vec2 eOffset = vec2(.2, -.1);
  vec2 fOffset = vec2(.0, .1);
  vec2 mOffset = vec2(.0, .11);

  vec2 sOffset = vec2(.0, .05);

  uv *= bass*2000.;

  uv.y *= 1.5;

  uv = rot(uv, .2+(-1.+2.0*bass)*1000.);

  c *= h(uv);

  uv += fOffset;

  c *= e(uv, eOffset);
  c *= e(uv, eOffset*vec2(-1., 1.));
  c *= n(uv);
  c *= m(uv, mOffset);
  c *= s(uv, sOffset, -0.25, 0.);
  c *= s(uv, sOffset, -0.15, 0.);
  c *= s(uv, sOffset,  0.1, 0.);
  c *= s(uv, sOffset, -.2, 1.);
  c *= s(uv, sOffset, -.1, 1.);
  c *= s(uv, sOffset, .1, 1.);

  out_color = vec4(c, 1.);
}