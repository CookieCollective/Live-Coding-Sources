
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
float box(vec3 p, vec3 b) {
  b=abs(p)-b;
  return min(max(b.x, max(b.y, b.z)),0.) + length(max(b, 0.));
}
float sc(vec3 p,float d){
  p=abs(p);p=max(p,p.yzx);
  return min(p.x,min(p.y,p.z))-d;
}

mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
vec3 re(vec3 p, float d){return mod(p-d*.5,d)-d*.5;}
float g=0.;
float de(vec3 p){
  //p.y+=.5;

  float t = time*6.;
  float s1 = .77+2.5*(t*.1+sin(t)*.1);
  p.xz*=r2d(s1);
  p.xy*=r2d(s1);


  float d= box(p, vec3(1));

  float s=1.;
  vec3 q = p;

  for(int m=0;m<3;m++) {
  q = re(p*s, 2.);
  s*=3.;
  d = max(d, -sc(2.-abs(q)*3., 1.)/s);
  }

  d = min(d, sc(1.-abs(q), .1));
  g+=.01/(.01+d*d);
  return d;
  return sc(p,.3);
  return length(p)-1.;
}
void main () {
  vec2 uv = gl_FragCoord.xy / resolution;
  uv -= .5;
  uv.x *= resolution.x / resolution.y + tan(time)*.4;

  vec3 ro=vec3(0,0,-2),rd=normalize(vec3(uv,.7-length(uv))),p;
  float ri,t=0.;
  for(float i=0.;i<1.;i+=.01) {
    ri=i;
    p = ro+rd*t;
    float d = de(p);
    //if(d<.001)break;
    d = max(abs(d), .002);
    t+=d*.5;
  }
  vec3 c = mix(vec3(.1, .3, .3), vec3(.1, .1, .2), length(uv*2.)+ri);
  c.r+=(sin(time*4.)*.5+.5)*.1;
  c+=g*.007;
  gl_FragColor = vec4(c, 1);
}
