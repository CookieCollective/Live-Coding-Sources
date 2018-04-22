
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }


mat2 rot(float a)
{
  float c = cos(a);float s = sin(a);
  return mat2(c,s,-s,c);
}

float map (vec3 pos) {
  float scene = 1000.;


  pos.xy *= rot(pos.z * .025);

  pos.xy *= rot(pos.z * .1 + time * 1.1);
  pos.x -= 10.;
  pos.x = abs(pos.x);


  pos.z = mod(pos.z + 1., 2.) - 1.;




  vec3 cp = abs(pos);


  vec3 cp1 = cp + vec3(1.,0.,0.) * 3.;
  vec3 cp2 = cp + vec3(-1.,0.,0.)* 3.;
  vec3 cp3 = cp + vec3(0.,1.,0.)* 3.;
  vec3 cp4 = cp + vec3(0.,-1.,0.) * 3.;

float decal = sin(time * 1. + pos.z * 5. + pos.x * .1) *.5 + .5;

decal = decal * .5 + .5;

  float c = max(max(cp1.x,cp1.y),cp1.z)-decal;
  scene = min(scene, c);
  c = max(max(cp2.x,cp2.y),cp2.z)-decal;
  scene = min(scene, c);
  c = max(max(cp3.x,cp3.y),cp3.z)-decal;
  scene = min(scene, c);
  c = max(max(cp4.x,cp4.y),cp4.z)-decal;
  scene = min(scene, c);
  return scene;
}



vec3 dumbCol(float d)
{
  return vec3(sin(d * .1) * .5 + .5, cos(d * .25) * .5 + .5, cos(d * 1.) *.5 + .5);
}

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(5.5,2.,-time * 3. + sin(time * 2.) * .5 + .5);
  uv.x = abs(uv.x);
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./60.) {
    float dist = map(pos);
    if (dist < .001) {
      shade = 1.-i;
      break;
    }
    pos += dist * ray;
  }
  vec3 color = vec3(1.);
  color *= shade;
  float c = length(uv - vec2(.05,.0));


float t = fract(time * .3) * 5.;
  c = step(c, .05 + t) -step(c, .03 + t);
  gl_FragColor = vec4(dumbCol(pos.z) * color + c, 1);

}
