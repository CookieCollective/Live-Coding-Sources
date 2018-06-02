
precision mediump float;

uniform vec2 resolution;
uniform float time;

vec3 lookat(vec3 eye, vec3 at, vec2 uv) {
  vec3 front = normalize(at-eye);
  vec3 right = normalize(cross(vec3(0,1,0), front));
  vec3 up = normalize(cross(front, right));
  return normalize(front + right * uv.x + up * uv.y);
}

mat2 rot (float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c,-s,s,c);
}
#define PI 3.14159
#define TAU (PI*2.)

void amod(inout vec2 p, float c) {
  float an = TAU/c;
  float a = mod(atan(p.y, p.x),an)-an/2.;
  p = vec2(cos(a),sin(a)) * length(p);
}

float siso(vec3 p, float s) {
  return dot(p, normalize(sign(p)))-s;
}

#define sdist(p,r) (length(p)-r)
#define repeat(p,c) (mod(p+c/2.,c)-c/2.)

float map (vec3 pos) {
  float scene = 1000.;
  vec3 p = pos;
  p.xz *= rot(time*.3);
  amod(p.xz, 5.);
  p.x -= .2;
  p = abs(p);
  p = repeat(p-time, 3.);
  p.xz *= rot(time*.9);
  p.yz *= rot(time*.6);
  p.xy *= rot(time*.3);
  // scene = min(scene, sdist(p.xz, .02));
  // scene = min(scene, sdist(p.xy, .02));
  // scene = min(scene, sdist(p.zy, .02));
  p = repeat(p, .8);
  // scene = min(scene, sdist(p, .03));
  p = pos;
  p.xz *= rot(p.y+time+sin(p.y-time));
  amod(p.xz, 5.);
  p.x -= .6+.2*sin(time*2.+p.y);
  // p.xz *= rot(p.y*20.+time);
  amod(p.xz, 3.);
  p.x -= .2;//+.05*sin(p.y*3.+time*2.);
  amod(p.xz, 3.);
  p.x -= .06;
  scene = min(scene, sdist(p.xz ,.01));
  p = pos;
  p.xz *= rot(time*.8);
  amod(p.xz, 8.);
  p.x -= 2.;
  p.x = repeat(p.x-time, 1.);
  // scene = min(scene, siso(p, .1));
  // scene = min(scene, sdist(p.xy, .02));
  // scene = min(scene, sdist(p.xz, .02));
  p = pos;
  p.xz *= rot(p.y-time);
  p.y = repeat(p.y+time, 1.);
  p.x -= 2.;
  // scene = min(scene, siso(p, .23));
  return scene;
}

vec3 raymarch () {
  vec3 pos = vec3(0,1,3);
  vec2 uv = (gl_FragCoord.xy-.5*resolution)/resolution.y;
  vec3 eye = pos;
  vec3 ray = lookat(eye, vec3(0), uv);
  float shade = 0.;
  vec3 color = vec3(1);
  for (float i = 0.; i < 1.; i += 1./60.) {
    float dist = map(pos);
    if (dist < 0.001) {
      shade = 1.-i;
      break;
    }
    pos += ray * dist;
  }
  // color.r = sin(pos.z*10.);
  color.gb *= sin(pos.y*3.)*.5+.5;
  color *= shade;
  color = pow(color, vec3(1./2.2));
  return color;
}

void main () {
  gl_FragColor = vec4(raymarch(), 1);
}
