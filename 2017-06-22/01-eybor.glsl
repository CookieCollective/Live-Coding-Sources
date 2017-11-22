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

vec2 rot(vec2 p, float angle)
{

  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle))*p;
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float box(vec3 p, vec3 dims)
{
  return max(abs(p.x-dims.x), max(abs(p.y - dims.y), abs(p.z - dims.z)));
}

float scene(vec3 p)
{
  return min(box(p+vec3(0., 5., 0.), vec3(3.)), p.y+ sin(p.x)*cos(p.z*.1)*3.);
}

vec3 n(vec3 p)
{
  vec2 e = vec2(0., .001);
  return normalize(vec3(scene(p-e.xyy)-scene(p+e.xyy),
scene(p-e.yxy)-scene(p+e.yxy),
scene(p-e.yyx)-scene(p+e.yyx)));
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 rd = normalize(vec3(-1.+2.*uv, 1.));

  vec3 o = vec3(0., 2., 5.);
  vec3 p = o;

  for(int i = 0; i < 256; ++i)
  {
    p += scene(p)*rd;
  }

  vec3 color = vec3(1.); 

  uv = rot(uv, fGlobalTime + texture(texFFTIntegrated, .15).x);

  color = vec3(max(dot(n(p), normalize(vec3(-2., -5., -3.))), 0.));

  color = mix(vec3(.5, .8,.9), color, max(1.-distance(p,o)*.001, 0.));

  vec4 tex = texture(texPegasus, p.xz+vec2(fGlobalTime));
  color = tex.w == 1. ? tex.xyz : color;

  out_color = vec4(color, 1.);
}