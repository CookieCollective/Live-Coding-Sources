#version 410 core

#define M_PI 3.141592

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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float cog(vec2 p)
{
  float angle = fract((M_PI+atan(p.x, p.y))/(2.*M_PI)*8.)*4.;

  float dist = sqrt(dot(p, p));
  float interpolationFactor = clamp(-1.+angle, 0., 1.) - clamp(-3.+angle, 0., 1.);
  
  return smoothstep(.7+interpolationFactor*.25, .75+interpolationFactor*.25, dist);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
uv *= 2.;  
uv -= 1.;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv *= 3.;

  vec2 prerot = uv;

  uv *= mat2(cos(fGlobalTime*.1), sin(fGlobalTime*.1), -sin(fGlobalTime*.1), cos(fGlobalTime*.1));

  vec2 rot = uv * mat2(cos(fGlobalTime), sin(fGlobalTime), -sin(fGlobalTime), cos(fGlobalTime));

  vec3 co = vec3(.5, .6, .8);

  prerot *= mat2(cos(fGlobalTime), sin(fGlobalTime), -sin(fGlobalTime), cos(fGlobalTime));

  co += smoothstep(0., 1., 1.-sqrt((prerot.x*prerot.x))*sqrt((prerot.y*prerot.y)))*.5;

  co *= cog(rot);

  rot = (uv+vec2(.5, 1.6)) * mat2(cos(-fGlobalTime), sin(-fGlobalTime), -sin(-fGlobalTime), cos(-fGlobalTime));

  co *= cog(rot*.9);
  
  rot = (uv-vec2(1.8, 0.)) * mat2(cos(-fGlobalTime), sin(-fGlobalTime), -sin(-fGlobalTime), cos(-fGlobalTime));
  
  co *= cog(rot*.8);

    out_color = vec4(co, 1.);
}