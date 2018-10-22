
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
  return mat2(c,s,-s,c);
}


float hash(float p)
{
  return fract(sin(p)*43557.);
}

float obj(vec3 p)
{
  float d = length(p.xy+vec2(cos(p.z+cos(time*.5)), sin(p.z+cos(time*.25))))-.1+cos(time)*.4;
d = min(d, -abs(p.y)+2.);
  return d;
}

float map(vec3 p)
{
  float d = cos(p.x)+cos(p.y*(cos(time)*.5+.5))+cos(p.z) + cos(p.y*10.)*.1;
  d = min(d, obj(p));
  return d;
}

vec3 normal(vec3 p)
{
  vec3 n;
  vec2 eps = vec2(0.01, 0.);
  float d = map(p);
  n.x = d - map(p-eps.xyy);
  n.y = d - map(p-eps.yxy);
  n.z = d - map(p-eps.yyx);
  return normalize(n);
}

vec3 raymarch(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<64; i++) {
    float d = map(p);
    p += rd * d;
  }
  return p;
}
vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n)
{
  vec3 col = n*.1+.5;

  col += vec3(rd.x,rd.y,.2) * length(ro-p)*.08;
  return col;
}


void main () {
  vec2 uv = gl_FragCoord.xy / resolution;
  uv.x *= resolution.x/resolution.y;
  vec3 ro = vec3(0.,0.,-2.+time*3.);
  vec3 rd = normalize(vec3(uv*2.-1., 1.));
rd.xy = rot(time*.1) * rd.xy;
rd.xz = rot(time*.5) * rd.xz;
  vec3 p = raymarch(ro,rd);
  vec3 n = normal(p);
  vec3 col = vec3(1.);
   col *= shade(ro,rd,p,n);

     if(obj(p) == map(p))
     {
       vec3 rro = p;
       vec3 rrd = reflect(rd,n);
       vec3 rp = raymarch(rro+n*.1, rrd);
       vec3 rn = normal(rp);
       col *= shade(rro,rrd,rp,rn);
     }
  gl_FragColor = vec4(col,1.);
}
