
precision mediump float;

uniform float time;
uniform vec2 resolution;

#define PI 3.14159
#define TAU (PI*2.)
#define repeat(p,c) (mod(p,c)-c/2.)

float sdSphere (vec3 p, float r) { return length(p) - r; }
float sdCyl (vec2 p, float r) { return length(p) - r; }
float sdDisk (vec3 p, float r, float h) { return max(length(p.xz) - r, abs(p.y) - h); }
float sdIso (vec3 p, float r) { return dot(p, normalize(sign(p))) - r; }

mat2 rot (float a) {
  float c = cos(a), s = sin(a);
  return mat2(c,-s,s,c);
}

void amod (inout vec2 p, float c) {
  float an = TAU/c;
  float a = mod(atan(p.y,p.x), an)-an/2.;
  p = vec2(cos(a),sin(a)) * length(p);
}

float map (vec3 pos) {
  float scene = 1000.;
  vec3 p = pos;

  vec3 pppp = p;
  p.xz *= rot(p.y * (.5 + .1 * sin(time * .1)) * .2);
  amod(p.xz, 5.);
  p.x -= 6.;
  vec3 ppp = p;

  scene = min(scene, sdCyl(p.xz, .04));

  float d = length(p);
  p = abs(p);
  p.xz *= rot(time + d * .1);
  p.yz *= rot(time + d * .1);
  p.xy *= rot(time + d * .1);
  scene = min(scene, sdCyl(p.xy, .04));
  scene = min(scene, sdCyl(p.xz, .04));
  scene = min(scene, sdCyl(p.zy, .04));

  float r = .3;

  vec3 pp = p;
  p.x = repeat(p.x - time, 1.);
  scene = min(scene, sdIso(p, r));
  scene = min(scene, sdCyl(p.xz, .03));

  p = pp;
  p.y = repeat(p.y - time, 1.);
  scene = min(scene, sdIso(p, r));
  scene = min(scene, sdCyl(p.yz, .03));

  p = pp;
  p.z = repeat(p.z - time, 1.);
  scene = min(scene, sdIso(p, r));
  scene = min(scene, sdCyl(p.xz, .03));
  scene = min(scene, sdCyl(p.yz, .03));

  scene = max(scene, sdSphere(pos, 8.));

  p = pppp;
  p.xz *= rot(p.y * .05);
  amod(p.xz, 16.);
  p.x -= 6. + 4. * (.5+.5*sin(p.y * .2 + time));
  scene = min(scene, sdCyl(p.xz, .05));

  p = pppp;
  p.xz *= rot(-p.y * .05);
  amod(p.xz, 16.);
  p.x -= 6. + 4. * (.5+.5*sin(p.y * .2 + time));
  scene = min(scene, sdCyl(p.xz, .05));

  p = pppp;
  p.y = repeat(p.y + time * 5., 10.);
  p.y += sin(atan(p.z,p.x)*5. + time * 5.);

   pp = pppp;
   amod(pp.xz, 32.);
   pp.x -= 9.;

  scene = min(scene, max(max(sdDisk(p, 10., .01), -sdCyl(p.xz, 8.)), -sdCyl(pp.xz, .5))); 
  //amod(p.yz, 32.);
  //p.z -= 5.;
  p.xz = repeat(p.xz, 2.);
  p.xz *= rot(d*.1);
  //scene = min(scene, sdCyl(p.xy, .01));
  //scene = min(scene, sdCyl(p.zy, .01));

  return scene;
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(0,10,-15);
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./30.) {
    float dist = map(pos);
    if (dist < .01) {
      shade = 1.-i;
      break;
    }
    pos += dist * ray;
  }
  vec3 color = vec3(1.);
  color = mix(vec3(.9,.2,.4),vec3(.1,.2,.8),sin(length(pos)*.6+time*5.));
  color *= shade;
  gl_FragColor = vec4(color, 1);
}
