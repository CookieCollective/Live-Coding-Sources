/*
"pixelRatio" : 1
*/

precision mediump float;
uniform float time;
uniform vec2 resolution;

float smin( float a, float b)
{
  float k = 2.;
  return -log( exp(-k*a) + exp(-k*b) )/k;
}

vec4 obj[4];

float map( vec3 p)
{
    float t  = time + floor(p.x/5.-2.5)*.5 + floor(p.z/10.-5.);
      obj[0] = vec4( cos(t*1.5),cos(t),cos(t*1.4),.25);
      obj[2] = vec4( cos(t*2.),cos(t),cos(t*.5),.125);
      obj[1] = vec4( cos(t),cos(t*.4),cos(t),.25);
      obj[3] = vec4( cos(t*1.),sin(t),cos(t),1.);
  p.xz = mod(p.xz, vec2(10.))-vec2(5.);
    float d = p.y+2.;
    d = smin(d, length(p-obj[0].xyz) - obj[0].w);
    d = smin(d, length(p-obj[1].xyz) - obj[1].w);
    d = smin(d, length(p-obj[2].xyz) - obj[2].w);
    d = smin(d, length(p-obj[3].xyz) - obj[3].w);
  return d;
}

vec3 normal(vec3 p)
{
  vec2 eps = vec2(0.01,0.);
  float d = map(p);
  vec3 n;
  n.x = d - map(p-eps.xyy);
  n.y = d - map(p-eps.yxy);
  n.z = d - map(p-eps.yyx);
  return normalize(n);
}

vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<128; i++)
  {
    float d = map(p);
    p += rd *d;

  }
  return p;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution -.5;
  uv.x *= resolution.x / resolution.y;

  vec3 ro = vec3(0.,1.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));

  vec3 p = rm(ro,rd);
  vec3 n = normal(p);

vec3 ld = normalize(vec3(-1.,.5,.1));


float shadow = 1.;

vec3 pp = rm(p+ld*.1, ld);

  vec3 col = vec3(1.) * max(0., dot(ld,n));
  if(length(p-pp)<10.)
    shadow = 0.;
  //col *= sign(cos(p.y*10.);
  col *= shadow;
  col = clamp(col,vec3(0.),vec3(1.)) + vec3(1.,.7,.5)*min(1.,length(p-ro)*.03);
  gl_FragColor = vec4(col, 1);
}
