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

#define time fGlobalTime
#define repeat(p,r) (mod(p,r)-r/2.)


float sbox(vec3 p, float r) {
  vec3 d = abs(p)-r;
  return max(d.x, max(d.y, d.z));
}
float sbox(vec3 p, vec3 r) {
  vec3 d = abs(p)-r;
  return max(d.x, max(d.y, d.z));
}

mat2 rot (float a) {
  float c=cos(a),s=sin(a);
  return mat2(c,s,-s,c);
}

float smoothmin (float a, float b, float r) {

  float h = clamp(.5+.5*(a-b), .0, 1.);
  return mix(b, a, r)-h*(1.-r)*r;
}

float map (vec3 pos) {
  float scene = 10.;
  vec3 p = pos;
  scene = max(-(length(pos.xy)-2.), 0.);

  p.z += time*4.;
  p.xy *= rot(p.z * .1 + sin(p.z - time) * .1);
  p = repeat(p, 1.);
  scene = max(scene, -sbox(p, .4));
  p = repeat(p, .8);
  scene = max(scene, -sbox(p, .2));
  p = repeat(p, .3);
  scene = max(scene, -sbox(p, .1));
  
  p = pos;
  p.z += time*4.;
  p.z = repeat(p.z, 4.);
  scene = max(scene, abs(p.z)-1.5);
  
  p = pos;
  p.xz *= rot(time*8.);
  p.yz *= rot(time*4.);
  //p.yx *= rot(sin(time*20.)*.5);
  vec3 pp = p;
  float shape = sbox(p, 0.3 + .1 * sin(time*4.) + 0.1 * sin(time*2.));
  p = repeat(p, .2);//+.1*sin(time*4.));
  shape = max(shape, sbox(p, .09));
  scene = min(scene, shape);

  p = pp;

  vec2 size = vec2(.1+.05*sin(time*40.), 4.);
  float d = length(pp) * .5;
  pp.xz *= rot(d);
  pp.yz *= rot(d);
  scene = min(scene, sbox(pp, size.xxy));
  scene = min(scene, sbox(pp, size.yxx));
  scene = min(scene, sbox(pp, size.xyx));


  const float count = 3.;
  for (float i = count; i > 0.; --i) {
    float r = i / count;
    p.xz *= rot(time);
    p.yz *= rot(time);
    p = abs(p)-(.3-.2 * sin(time*8.))*r;
    scene = min(scene, length(p)-.2*r);
  }

   p = abs(p)-.5;

  scene = min(scene, sbox(p, .1));

  return scene;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv *= rot(time);

  vec3 eye = vec3(0,0,-4);
  vec3 pos = eye;
  vec3 ray = normalize(vec3(uv, .6 + .4 * sin(time*2.5)));
  float shade = 0.;
  const float count = 60.;
  for (float i = count; i > 0.; --i) {
    float dist = map(pos);
    if (dist < .001) {
      shade = i / count;
      break;
    }
    pos += ray * dist * .5;
  }
  vec3 disco = vec3(.5)+vec3(1.)*sin(vec3(.1,.2,.3)*time*10. - pos.z * .5);
  vec3 color = mix(disco, vec3(1,0,0), step(length(pos), 1.));
  out_color = vec4(color*shade, 1);
}