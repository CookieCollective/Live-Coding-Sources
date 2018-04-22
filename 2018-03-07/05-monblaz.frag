
precision mediump float;

uniform float time;
uniform vec2 resolution;

float sdSphere (vec3 p, float r) { return length(p) - r; }

mat2 r2d(float a){
  float c = cos(a), s=sin(a);
  return mat2(c, s, -s, c);
}

void lw(inout vec3 p) {
  p.xz *= r2d(time);
  p.xy *= r2d(time);
  //return p;
}

float g=0.;
float map (vec3 p) {


float pl=p.y+1.;
  lw(p);

  //float scene = 1000.;
  //scene = min(scene, sdSphere(pos, 1.));
  float d = length(max(abs(p) - .7, 0.));
  d = min(d, pl);
  g+=.01/(.01+d*d);
  return d;
}



vec3 lookAt (vec3 eye, vec3 at, vec2 uv) {
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

vec3 tex(vec2 p){
  float pl=1., o=0.;
  float t = sin(time*20.);
  float a = -.35 + t*.02;

  p.x *=1.2;
  p*=r2d(a);

  p*=.07;
  p+=vec2(.71, t*.014 - .56) + t*.017;
  for(int i=0;i<13;i++) {
    p.x = abs(p.x);
    p*=2.;
    p+=vec2(-2., .85) - t*.04;
    p /= min(dot(p,p), 1.03);
    float l = length(p*p);
    o += exp(-1.2 / abs(l-pl));
    pl = l;
  }

  o*=.07;
  o*=o;

  return vec3(.8, .8*o, o*o*.9) * o * 2. + .1;
}

vec3 normal(vec3 p) {
  vec2 e = vec2(.01, 0.);
  return normalize(vec3(
    map(p+e.xyy) - map(p-e.xyy),
    map(p+e.yxy) - map(p-e.yxy),
    map(p+e.yyx) - map(p-e.yyx)
    ));
}

vec3 boxmap(vec3 p, vec3 n) {
  vec3 m = pow(n, vec3(32.));
  vec3 x = tex(p.yz);
  vec3 y = tex(p.zx);
  vec3 z = tex(p.xy);
  return (m.x*x, m.y*y, m.z*z) / (m.x+m.y+m.z);

}

void main () {
//  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
vec2 uv = (gl_FragCoord.xy/resolution.xy) - .5;
uv.x *= resolution.x / resolution.y;

//  vec3 eye = vec3(0,1,-3);
//S  vec3 ray = lookAt(eye, vec3(0), uv);
  //vec3 pos = eye;

  vec3 ro = vec3(0, 0, -4);
  vec3 rd = normalize(vec3(uv, 1));
  vec3 p;
//  float shade = 0.;
  float t = 0.;
  for (float i = 0.; i < 1.; i += .01) {
    p=ro+rd*t;
    float dist = map(p);
    if (dist < .001) {
      //shade = 1.-i;
      break;
    }
    t += dist;
  }


  vec3 n = normal(p);
  lw(p);lw(n);
  vec3 color = boxmap(p, n);//tex(uv);
  //color += g*.01;

//  color = vec3(n);;
//  color *= shade;
  gl_FragColor = vec4(color, 1);
}
