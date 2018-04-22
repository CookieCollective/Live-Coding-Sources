
// fluxus
// dave griffits

precision mediump float;

uniform float time;
uniform vec2 resolution;

#define PI 3.14159
#define TAU (PI*2.)
#define repeat(p,c) (mod(p+c/2.,c)-c/2.)

float sdSphere (vec3 p, float r) { return length(p) - r; }
float sdCylinder (vec2 p, float r) { return length(p) - r; }
float sdIso (vec3 p, float r) { return dot(p, normalize(sign(p))) - r; }

vec2 amod (vec2 p, float c) {
  float ac = TAU/c;
  float a = mod(atan(p.y,p.x), ac)-ac/2.;
  return vec2(cos(a),sin(a)) * length(p);
}

mat2 rot (float a) {
  float c = cos(a), s = sin(a);
  return mat2(c,-s,s,c);
}

float map (vec3 pos) {
  float scene = 1000.;
  vec3 p = pos;
  // p.xz = amod(p.xz, 5.);
  p = repeat(p, 3.);
  p.xz *= rot(p.y + time * .3);
  // p = abs(p);
  // p.x -= .5;
  p.xz *= rot(time*.9);
  p.yz *= rot(time*.6);
  p.yx *= rot(time*.3);
  scene = min(scene, sdIso(p, .5));
  // scene = min(scene, sdCylinder(p.xz, .01));
  // scene = min(scene, sdCylinder(p.yz, .01));
  // scene = min(scene, sdCylinder(p.yx, .01));
  return scene;
}

vec3 getNormal (vec3 p) {
  vec2 e = vec2(.001,0.);
  return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(0,.5,-2);
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./30.) {
    float dist = map(pos);
    if (dist < .001) {
      shade = 1.-i;
      break;
    }
    pos += dist * ray;
  }
  vec3 color = vec3(1.);
  color = getNormal(pos) * .5 + .5;
  color *= shade;
  gl_FragColor = vec4(color, 1);
}
