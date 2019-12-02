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

#define time fGlobalTime

layout(location = 0) out vec4 color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );

  
}

mat2 rot (float a) {
  float c=cos(a);
  float s = sin(a);
  return mat2(c,s,-s,c);
}

#define repeat(p,r) (mod(p,r)-r/2.)

float map (vec3 p) {
  p.z = repeat(p.z+time*1., 4.);
  float scene = 10.;
  float wave = sin(time*4.)*.5+.5;
  float wave2 = sin(time*12.)*.5+.5;
  const float count = 6.;
  float range = 1.;
  float a = 1.;
  float falloff = 1.8;
  vec3 op = p;
  for (float i = count; i > 0.; i--) {
    p.xz *= rot(time*.1);
    p.yz *= rot(time*.2);
    p.yx *= rot(time*.3);
    //p.yx *= rot(sin(time*8.)*.1);
    p = abs(p)-(range)*a;
    scene = min(scene, length(p.xy)-(.4-.01*wave2)*a);
    scene = min(scene, length(p)-(.9-.01*wave2)*a);
    a /= falloff;
  }
  scene = abs(scene) - .001;
  scene = max(scene, -length(op.xy)+.4);
  return scene;
}

vec3 getNormal (vec3 p) {
  vec2 e = vec2(.001,0);
  return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

    vec3 eye = vec3(0,0,-2);
  float wave = sin(time*8.)*.5+.5;
  vec3 ray = normalize(vec3(uv,.3));
  ray.xz *= rot(sin(time*.6)*.2);
  ray.yz *= rot(sin(time*.3)*.1);
  vec3 pos = eye;
  float shade = 0.;
  const float count = 40.;
  for (float index = count; index > 0.; index--) {
    float d = map(pos);
    if (d < 0.01) {
      shade = (index / count);
      break;
    }
    pos += ray * d;
  }
  vec3 normal = getNormal(pos);
  //color.rgb = normal * .5 + .5;
  color.rgb += vec3(.2,.8,.9) * clamp(dot(normal, -ray), 0., 1.);
  color.rgb += vec3(2) * pow(clamp(dot(normal, vec3(0,0,-1))*.5+.5, 0., 1.), 24.);
  color *= shade;
}