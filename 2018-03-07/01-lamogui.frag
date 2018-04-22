
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }

float box(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec3 curve(float t)
{
  return vec3(cos(t*0.2), sin(t*0.4), 0.0);
}

float map (vec3 p) {
  p -= 0.5;
  float p2 = 10.0;
  p.x = mod(p.x, p2) - p2 *0.5;
  p += curve(p.z);
  float scene = 1000.;
  //scene = min(scene, sdSphere(pos, 1.));
  float period = 2.1;
  vec3 q = p;
  q.z = mod(p.z, period) - 0.5 * period;
  scene = min(scene, box(q, vec3(3.0, 1.0,1.0)));
  vec3 q2 =p;
  q2.z = mod(p.z + period * 0.5, period) - 0.5 * period;
  scene = min(scene, box(q2 - vec3(-1.5, 1.0, 0.0), vec3(1.5, 0.3, 0.5)));
  return scene;
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}
/*
vec3 map(vec3 p)
{
  vec2 eps = vec2(0.01, 0.0);
  return normalize(vec3(map(p + eps.xyy) - map(p - eps.xyy), map(p + eps.yxy) - map(p - eps.yxy), map(p + eps.yyx) - map(p - eps.yyx)));
}*/

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(0,3.0,time * 10.0);
  vec3 ray = normalize(vec3(uv, 0.6 - length(uv)));//lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./64.) {
    float dist = map(pos) * 0.4;
    if (dist < .001) {
      shade = 1.-i;
      break;
    }
    pos += dist * ray;
  }
  vec3 color = vec3(1.);
  color = vec3(exp(-distance(pos, eye) * 0.05)) * shade;
  //vec3 rd2 = reflect(ray, )
  //vec3 ro2 = pos +

  //color *= shade;
  gl_FragColor = vec4(color, 1);
}
