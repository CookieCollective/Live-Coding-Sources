/*{
"pixelRatio" : 3
}*/

precision mediump float;
uniform float time;
uniform vec2 resolution;

float rep(float p, float d) {
  return mod(p-d*.5, d)-d*.5;
}

vec3 rep(vec3 p, float d) {
  return mod(p-d*.5, d)-d*.5;
}

void mo(inout vec2 p, vec2 d){
  p.x = abs(p.x) - d.x;
  p.y = abs(p.y) - d.y;
  if(p.y>p.x)p=p.yx;
}

void amod(inout vec2 p, float m) {
  float a = rep(atan(p.x, p.y), m);
  p = vec2(cos(a), sin(a)) * length(p);
}

vec2 path(float t) {
  float a =sin(t*.2+1.5), b=cos(t*.2);
  return vec2(a*2., a*b);
}

vec3 g;

float sc(vec3 p) {
  p = abs(p);
  p = max(p, p.yzx);
  return min(p.x, min(p.y, p.z)) - .02;
}

float de(vec3 p){
  p.xy -= path(p.z);

  amod(p.xy, 3.14);
  mo(p.xy, vec2(.3, 3.));
  mo(p.xy, vec2(.9, .3));
  float d = length(p.xy) - .03;
  d = min(d, length(rep(p, 4.)) - .1);

  amod(p.xy, .785);
  mo(p.zy, vec2(1., 1.2));
  p.z = rep(p.z, 1.);
  d = min(d, sc(p));

  vec3 q = p;
  mo(q.xy, vec2(3., 2.));
  q = rep(q, 10.);
  d = min(d, sc(q));

  g += vec3(.5, .6, .5) * .025 / (.01+d*d);
  return d;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution -.5;
  uv.x *= resolution.x / resolution.y;

  float dt = time*6.;
  vec3 ro = vec3(0, 0, -4. + dt);
  vec3 ta = vec3(0, 0, dt);
  ro.xy += path(ro.z);
  ta.xy += path(ta.z);
  vec3 fwd = normalize(ta - ro);
  vec3 left = cross(vec3(0, 1, 0), fwd);
  vec3 up = cross(fwd, left);
  vec3 rd = normalize(fwd+uv.x*left+uv.y*up);

  float ri, t = 0.;
  for(float i=0.;i<1.;i+=.01){
    ri=i;vec3 p = ro+rd*t;
    float d = de(p);
    if(d<.001||t>100.) break;
    t+=d*.2;
  }

  vec3 c = mix(vec3(.9, .2, .4), vec3(.3, cos(time)*.1, .2), uv.x+ri);
  c.r *= sin(time);
  c += g*.02;
  gl_FragColor = vec4(c, 1);
}
