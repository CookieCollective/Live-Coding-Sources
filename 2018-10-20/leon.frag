
precision mediump float;

uniform vec2 resolution;
uniform float time;


vec3 lookat (vec3 eye, vec3 at, vec2 uv) {
  vec3 front = normalize(at-eye);
  vec3 right = normalize(cross(front, vec3(0,1,0)));
  vec3 up = normalize(cross(front, right));
  return normalize(front + right * uv.x + up * uv.y);
}

mat2 rot (float a) {
  float c = cos(a), s = sin(a);
  return mat2(c,-s,s,c);
}

float smin (float a, float b, float r) {
  float h = clamp(.5+.5*(b-a), 0., 1.);
  return mix(b,a,h)-r*h*(1.-h);
}

float repeat( float p, float c) { return mod(p,c)-c/2.; }

float map (vec3 pos) {
  float scene = 10.;
  const float count = 8.;
  // pos.xz *= rot(length(pos));
  vec3 p = pos;
  // p.xz *
  float s = 10.;
  for (float i = count; i > 0.; --i) {
    float r = i / count;
    pos = abs(pos)-.2*r;
    pos.xz *= rot(time * .05);
    // pos.xz *= rot(sin(time * 4.)*.5);
    pos.yz *= rot(time * .01);
    // pos.yx *= rot(time * 1.5);
    float b = .24 * r;
    // scene = smin(scene, length(pos)-.1*r, b);//+.5*sin(time));
    // scene = smin(scene, length(pos.xz)-.1*r, b);//+.5*sin(time));
    scene = min(scene, max(pos.x, max(pos.y, pos.z)));
    vec3 pp = pos;
    // pp.xy *= rot(time * .2);
    // pp.zy *= rot(sin(time*8.) * .2);
    // pp.xz *= rot(time * .4);
    s = min(s, length(pp.yz)-.01);

    pp.x = repeat(pp.x + time * .01, .4);
    s = min(s, length(pp)-.1*r);
    // s = min(s, length(pp.xz)-.01*r);
  }
  scene = max(-scene, length(p)-1.);
  scene = min(scene, s);
  // scene = length(pos)-.1;//+.5 * sin(time*5.);
  return scene;
}

void main () {
  vec2 uv = gl_FragCoord.xy / resolution;
  uv = uv * 2. - 1.;
  uv.x *= resolution.x / resolution.y;
  vec3 eye = vec3(0,0,-3.);
  eye.z += sin(time * 2.) * .25;
  eye.xz *= rot(time*.5);
  eye.yz *= rot(time*.5);
  vec3 target = vec3(0);
  vec3 ray = lookat(eye, target, uv);
  float shade = 0.;
  const float count = 30.;
  for (float i = count; i > 0.; --i) {
    float dist = map(eye);
    if (dist < .001) {
      shade = i / count;
      break;
    }
    eye += ray * dist;
  }
  vec3 color = vec3(.5) + vec3(.5) * cos(time*vec3(.1,.2,.3)*4. + shade * 4.);
  gl_FragColor = vec4(color*shade, 1.);
}
