
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }

mat2 rot(float a)
{
  float c  = cos(a); float s = sin(a);
    return mat2(c,-s,s,c);
}

float map (vec3 pos) {
  float scene = 1000.;


  vec3 posP = pos;
  //posP.y += sin(posP.x * 1.);

  float plane = posP.y + 2.;

 vec3 pos2 = pos;


 pos2. y += sin(time) * 1. - 2.;

 pos2.xz *= rot(time);
 pos2.x = abs(pos.x);
 pos2.y -= pos2.x;

   scene = min(scene,plane);
  scene = min(scene, sdSphere(pos2, 1.));

vec3 posCy = pos;


posCy.x = mod(posCy.x +2.5, 5.) - 2.5;
posCy.x += sin(time + pos.z);

float cyle = distance(posCy.xy,vec2(0.,-1.)) - 1.;

scene = min(scene,cyle);

  return scene;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.001,.0);
  return normalize(
    vec3(
        map(p - e.xyy) - map(p + e.xyy),
            map(p - e.yxy) - map(p + e.yxy),
                map(p - e.yyx) - map(p + e.yyx)
      )
    );

}


vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(0,5,-10);
  vec3 ray = lookAt(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  for (float i = 0.; i <= 1.; i += 1./100.) {
    float dist = map(pos);
    if (dist < .001) {
      shade = 1.-i;
      break;
    }
    pos += dist * ray;
  }
vec3 light = vec3 (0. + sin(time),-10. ,  12.* cos(time));
vec3 norm = normal(pos);
float li = dot(normalize(light - pos), norm);


  vec3 color = vec3(1.);
  color *= li;
  gl_FragColor = vec4(norm * color * .75 + .2, 1);
}
