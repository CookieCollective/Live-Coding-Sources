#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
#define P 3.1415

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

float circlesdf(vec2 uv) {
  return distance(uv, vec2(0.5));
}
  
void main(void)
{
  vec2 uv = 2.0 * gl_FragCoord.xy / v2Resolution.xy - 1.0;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv += 0.5;
  
  float t = fGlobalTime;
  
  vec3 color = vec3(0.0);
  
  float mixer = mix(
    0.5, 1.0,
    mod(t, 2.5)
  );
   float mixer2 = mix(
    0.5, 2.5,
    mod(t, 1.0)
  );
  float n = 7.5 + 2.0 * sin(2.5 * t + uv.x);
  uv *= mixer * n;
  vec2 gv = fract(uv);
  vec2 id = floor(uv);
  
  float p1 = sin(5.0 * t + id.x + gv.x) *
    cos(-t + id.y + cos(5.0 * t + uv.x * uv.y) - 5.0 * sin(-t + uv.x + uv.y))
    * 0.25 + 0.25;
  float p2 = sin(5.0 * t + id.x + gv.x) *
    cos(t + id.y + cos(5.0 * t + uv.x - uv.y) - 5.0 * sin(-t + uv.x + uv.y))
    * 0.25 + 0.25;
  
  color += smoothstep(p1, p2, circlesdf(gv));
  color.b += smoothstep(p2, p1, circlesdf(gv));
  
  out_color = vec4(color, 0.0);
}