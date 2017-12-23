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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

#define sdist(p,s) (length(p)-s)
#define STEPS 50.

float map (vec3 pos) {
  float scene = 1000.;
  vec3 p = pos;
  scene = min(scene, sdist(p, 1.));
return scene;

}

#define repeat(p,s) (mod(p,s)-s/2.)

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
uv.x *= v2Resolution.x/v2Resolution.y;
  float shade = 1;
  
  //uv = repeat(uv, .5);
  uv.y -= mod(abs(uv.x/(0.2+ mod(fGlobalTime, 10))) *91 - uv.x*0.1, 1);
uv.x *= 0.7;

float heart = step(.4, length(uv));

  shade = heart;

  float a = atan(uv.y, uv.x);
  float r = length(uv);
  uv = vec2(a,r);
  float v = 1.1;

  out_color = vec4(1.-shade, 0, 0,1.);
  out_color = mix(uv.y*vec4(0.457, 0.734, 0.276, 1), vec4(0.835, 0.457, 0.0345, 1), mix(vec4(1,1,1,1), vec4(0,0,0,0), out_color.r));
  out_color *= vec4(1-(uv.x+0.5));

}