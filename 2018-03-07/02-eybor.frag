
precision mediump float;

uniform float time;
uniform vec2 resolution;

float scene(vec3 p)
{
  return p.y;
}

vec3 rm(vec3 o, vec3 r)
{
  vec3 p = o;

  for(int i = 0; i < 512; ++i)
  {
    float d = scene(p);
  }

  return p;
}

float rand(vec2 uv)
{
  return fract(sin(dot(vec2(12.9898, 78.233), uv))*43758.5453);
}

vec3 sc(vec3 p, vec2 uv)
{
  vec3 co = vec3(0., 0.07, .14);

  co += smoothstep(.99, 1., rand(uv));
  float md = length(uv-vec2(-.8, .4));

  co = mix(co, vec3(1.), 1.-smoothstep(.12, .125, md));



  co += .5*exp(-4.*md)*vec3(1.2, 1.1, .8);
  co += .2*exp(-2.*md);

  return co;
}

void main () {
  vec2 uv = -1.+2.*gl_FragCoord.xy / resolution.xy;
  uv.x *= gl_FragCoord.x/gl_FragCoord.y;
  vec3 rd = normalize(vec3(uv, -1.));
  vec3 o = vec3(0., 0., 0.);
  vec3 p = rm(o, rd);

  vec3 rp = o-(100.-o.y)/(rd/rd.y);

vec3 co = sc(rp, uv);

  gl_FragColor = vec4(co, 1);
}
