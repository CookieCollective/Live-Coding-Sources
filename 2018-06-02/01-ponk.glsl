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

#define PI 3.14159
#define TAU (2.*PI)
#define repeat(p,c) (mod(p+c/2.,c)-c/2.)
#define time fGlobalTime

mat2 rot (float t) {
  float c = cos(t), s = sin(t);
  return mat2(c,s,-s,c);
}

void amod (inout vec2 p, float c) {
  float an = TAU / c;
  float a = atan(p.y,p.x)+c/2.;
  a = mod(a, an)-an/2.;
  p = vec2(cos(a),sin(a)) * length(p);
}

float box ( vec3 p , vec3 r) {
  vec3 d = abs(p)-r;
  return max(d.x,max(d.y,d.z));
}

float map (vec3 pos) {

  float scene = 10.;
const float count = 5.;
for (float i = count; i >= 0.; --i) {
float r = i / count;
r = r * r;
vec3 p = pos;
p = abs(p)-1.*r;
p.xz *= rot(r* time);
p.yz *= rot(r*time * .5);
  float a = atan(p.x,p.z);
amod(p.xz, 5.);
  p.x = repeat(p.x - time, 2. * r);
  //p.x -= 1. + sin(a * 4. + time) * .25;
  scene = min(scene, length(p)-.2*r);
  scene = min(scene, length(p.yz)-.01*r);
}
  vec3 p = pos;
float d = length(p) * .5;
p.xz *= rot(time+d);
p.yz *= rot(time*.6+d);
p.yx *= rot(time*.3+d);
float scale = .4 + sin(time * 5.) * .2;
  scene = min(scene, box(p, scale*vec3(1.)));
  scene = max(scene, -box(p, scale*vec3(.9,10.,.9)));
  scene = max(scene, -box(p, scale*vec3(10.,.9,.9)));
  scene = max(scene, -box(p, scale*vec3(.9,.9,10.)));
//p.yz *= rot(p.x + time);
vec3 pp = p;
p.x = repeat(p.x + time, .2);
d *= .05;

  scene = min(scene, box(p, vec3(.025+d)));

p = pp;
p.y = repeat(p.y + time, .2);  
  scene = min(scene, box(p, vec3(.025+d)));

p = pp;
p.z = repeat(p.z + time, .2);
  
  scene = min(scene, box(p, vec3(.025+d)));
  return scene;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float shade = 0.;
  vec3 eye = vec3(1,1,-3);
  eye.xz *= rot(time*.3);
  eye.xy *= rot(time*.1);
eye = normalize(eye) * length(eye) * (1.+sin(time/2.)*.5);
 vec3 target = vec3(0,0,0);
  vec3 forward = normalize(target - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  vec3 ray = normalize(forward + uv.x * right + uv.y * up);
  vec3 pos = eye;

  //float f = texture( texFFT, d ).r * 100;

  const float count = 50.;
  for ( float i = count; i >= 0.; --i) {
    float dist = map(pos);
    if (dist < .0001) {
      shade = i/count;
      break;
    }
    pos += ray * dist;
  }

  //float f = texture( texFFT, d ).r * 100;
float t = - time + length(pos) * 2. + shade * 16.;
  vec3 color = vec3(.5)+vec3(.5)*cos(t*vec3(.1,.2,.3));
color *= 2.5;
color *= shade;
  out_color = vec4(color, 1.);
}