
precision mediump float;

uniform float time;
uniform vec2 resolution;

#define repeat(p,r) (mod(p+r/2.,r)-r/2.)

float sdSphere (vec3 p, float r) { return length(p) - r; }

mat2 rot (float a) { float c = cos(a), s = sin(a); return mat2(c,-s,s,c); }

float smin (float a, float b, float r) {
  float h = clamp(.5+.5*(b-a)/r, 0., 1.);
  return mix(b, a, h)-r*h*(1.-h);
}

void amod (inout vec2 p, float c) {
  float an = (3.1459*2.)/c;
  float a = atan(p.y,p.x)+an/2.;
  a = mod(a, an) - an/2.;
  p = vec2(cos(a), sin(a)) * length(p);
}

float map (vec3 pos) {
  float scene = 1000.;
vec3 pp = pos;
    pos.xz *= rot(time*.09554);
    // pos.xz *= rot(pos.y * .5 + time);
    pos.yz *= rot(time*.62468);
    float smoo = .01;
    const float count = 5.;
  for (float i = count; i > 0.; --i) {
    float r = i / count;
    r = r * r;
  pos = abs(pos) - 1.5 * r;
      pos.xz *= rot(time*.94645);
      pos.yz *= rot(time*.56546);
      pos.xy *= rot(time*.31546);
  vec3 p = pos;
  // p.y = repeat(p.y + time, .4);
  scene = smin(scene, sdSphere(p, .1), smoo);
  // scene = smin(scene, max(abs(p.y)-.01, length(p.xz) - .1), smoo);
  scene = min(scene, length(p.yz) - .02);
  // scene = min(scene, length(p.yx) - .1);
}
scene = max(scene, -sdSphere(pp, 3.));
float d = length(pp);
vec3 p = pp;
pp.xz *= rot(-time*1.798+d);
pp.yz *= rot(-time*1.698+d);
pp.yx *= rot(-time*1.398+d);
scene = min(scene, length(pp.xz)-.1*d);
scene = min(scene, length(pp.yz)-.1*d);
scene = min(scene, length(pp.yx)-.1*d);
pp = p;
pp.xz *= rot(pp.y + time / 4.);
pp.y = repeat(pp.y + time, .5);
amod(pp.xz, 5.);
pp.x -= 1. + .5 * sin(p.y + time / 2.);
scene = min(scene, sdSphere(pp, .1));
scene = min(scene, length(pp.zy)- .02);


  return scene;
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward * .3 + right * uv.x + up * uv.y);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(0,0,-2.+.5*sin(time*4.));
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./100.) {
    float dist = map(pos);
    if (dist < .001) {
      shade = 1.-i;
      break;
    }
    // if (shade >= 1.) break;
    // dist = max(.05, dist);
    pos += dist * ray;
  }
  vec3 color = vec3(1.);
  vec3 t = vec3(.1,.2,.3) * time + length(pos) / 2. + shade * 8.;
  color = vec3(.5)+vec3(.5)*cos(t);
  color *= shade;
  gl_FragColor = vec4(color, 1);
}
