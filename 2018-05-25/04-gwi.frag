
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }

float sdCube(vec3 p, float r) { return min(abs(p.x - 0.5) * mod(time, 0.2), abs(p.y - 0.5) * mod(time, 0.6)); }

float map (vec3 pos) {
  float scene = 1000.;
  scene = min(scene, sdCube(pos, 0.4));
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
  vec3 eye = vec3(0,1,-3);
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float SpherePos = -0.8; SpherePos < 0.8; SpherePos += 0.2)
  {
    for (float i = 0.; i <= 1.; i += 1./60.) {
      float dist = sdCube(pos, 0.5);
      dist = dist * sdSphere(pos, 0.1);
      //dist += sdSphere(pos, 0.8);
      pos += mod(time, 0.2);
      dist += sdSphere(vec3(0.9, 0., 0.) + pos, 0.5);
      if (dist < .001) {
        shade = 1.-i;
        break;
      }
      pos += dist * ray;
    }
  }

  vec3 color = vec3(mod(time, 1.), mod(time, 0.1), mod(time, 0.3));
  color *= shade;
  gl_FragColor = vec4(color, 1);
}
