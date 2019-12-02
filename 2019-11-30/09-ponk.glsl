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

layout(location = 0) out vec4 color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
#define time fGlobalTime

mat2 rot (float a) {
  float c=cos(a), s= sin(a); return mat2(c,s,-s,c);
}

#define repeat(p,r) (mod(p,r)-r/2.)

float map (vec3 pos) {
  pos.z = repeat(pos.z + time *2., 4.);
  float scene = 1.;
  vec3 p = pos;
  const float count = 8.;
  float range = 0.5;
  float falloff = 1.5;
  float a = 1.;
  for (float index = count; index >0.; index--) {
    pos = abs(pos)-range*a;
    pos.xz *= rot(.1*time/a);
    pos.yz *= rot(sin(16.*time/a)*.1);
    scene = min(scene, max(pos.x, max(pos.y, pos.z)));
    a /= falloff;
  }
  //scene = max(scene, -1.);
  scene = abs(scene-.01);
  scene = max(scene, length(p)-4.);
  scene = max(scene, -length(p)+.5);
  scene = max(scene, -length(p.xy)+.5);
  return scene;
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec3 eye = vec3(0,.0,-.2);
  vec3 ray = normalize(vec3(uv, .1));
  ray.xy *= rot(sin(time)*.1);
  ray.xz *= rot(sin(time*.2)*1.8);
   vec3 pos = eye;
  
  
  float shade = 0.;
  const float count = 40.;
  for (float index = count; index > 0.; index--) {
    float d = map(pos);
    if (d < 0.001) {
      shade = index / count;
      break;
    }
    pos += ray * d;
  }
  color.rgb += vec3(.8)+vec3(.9)*cos(vec3(.1,.2,.3)*(time*5.+shade*10.));
  color *= vec4(shade);
}