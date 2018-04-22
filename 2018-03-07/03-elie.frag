
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }

float map (vec3 pos) {
  float scene = 1000.;
  //pos = mod(pos, vec3(10.0)) - vec3(5);
  pos.x *= 1. / (1. + pos.y);
  scene = min(scene, sdSphere(pos, 1. + pos.x * (2.0 + 0.5 * sin(time * 1.5))));
  return scene;
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

float grain(vec2 uv) {
  return fract(sin(dot(uv, vec2(31.492, 271.0))));
}

vec3 mainmain(vec2 uv) {
  vec3 eye = vec3(0,1,-3);
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
  vec3 color = vec3(1., 0.5, 0.);
  color.r += 0.2 * sin(1.0*time);
  color += 0.5*dot(vec3(0.5, exp(pow(sin(time), 2.)), 0.5), pos);
  color.z += 0.6*grain(uv + grain(uv) * vec2(1.0, 2.0+sin(100.*time)));
  float s = sin(time);
  float c = cos(time);
  vec3 c2 = color;
  c2.r = s * color.g + c * color.r;
  c2.g = -s * color.r + c * color.g;
  color += (0.2) * c2;
  color *= shade;
  return color;
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 c = vec3(0);
  float r = pow(10., -2.-2.*(1.-pow(sin(2.*time), 10.) - pow(sin(2.315*time), 10.)));
  c += mainmain(uv+vec2(r, r));
  c += mainmain(uv+vec2(r, -r));
  c += mainmain(uv+vec2(-r, r));
  c += mainmain(uv+vec2(-r, -r));
  c /= 4.;
  gl_FragColor = vec4(c, 1);
}
