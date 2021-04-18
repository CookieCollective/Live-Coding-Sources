#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
#define sat(a) clamp(a, 0., 1.)
float _time;
mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s,s,c);}
vec3 getCam(vec3 rd, vec2 uv)
{
  float fov = 1.;
  vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
  vec3 u = normalize(cross(rd, r));
  return normalize(rd+fov*(uv.x*r+uv.y*u));
}

float _cube(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
  l = abs(l)-s*.5;
  l.z += sin(_time+p.y);
  l.xy *= r2d(_time);
  l = abs(l)-s*.25;
  l.yz *= r2d(_time);
  return max(l.x, max(l.y, l.z));
}

vec2 map(vec3 p)
{
  vec3 pc = p;
  pc.xz *= r2d(_time);
  pc.xy *= r2d(_time*.5);
  vec2 cube = vec2(_cube(pc, vec3(1.)), 0.);

  return cube;
}

vec3 trace(vec3 ro, vec3 rd, int steps)
{
  vec3 p = ro;
  for (int i = 0; i < steps; ++i)
  {
    vec2 res = map(p);
    if (res.x < 0.01)
      return vec3(res.x, distance(p, ro), res.y);
    p+= rd*res.x*.25;
  }
  return vec3(-1.);
}

float lenny(vec2 v)
{
  return abs(v.x)+abs(v.y);
}

vec3 rdr(vec2 uv)
{
  vec3 col;
  
  vec3 ro = vec3(0.,0.,-15.);
  vec3 ta = vec3(0.,0.,0.);
  vec3 rd = normalize(ta-ro);
  rd = getCam(rd, uv);
  
  vec3 res = trace(ro, rd, 128);
  if (res.y > 0.)
  {
    vec3 p = ro+rd*res.y;

    vec3 n = normalize(cross(dFdx(p), dFdy(p)));
    col = sat(n*.5+.5)*pow(sat(dot(n, normalize(vec3(1.)))),5.);
    col += vec3(1.)*distance(p, ro)*.05;
    }
  float borders = max(sin((uv.x+uv.y)*50.+_time*sign(uv.x)), -(abs(uv.x)-.4));
  vec3 rgb = mix(vec3(.25,.367,.96), vec3(.87,.15,.96), sat(sin(uv.y*10.)*.5+.5));
  col = mix(col, rgb, 1.-sat(borders*400.));

  col += .5*vec3(1.)*pow(1.-sat(lenny(uv)),5.)*vec3(1.,2.,4.)*(uv.xyx*.5+.5+sat(sin(_time)));
  return col;
}
vec3 rdr3(vec2 uv)
{
    vec3 col = rdr(uv)*.75;
  uv *= r2d(_time);

  vec2 uv2 = uv;
  float stp = 0.1;
  uv2 = floor(uv/stp)*stp;
  col += rdr(uv2*4.).zxy*.25*pow(sat(length(uv)),.5);
return col;
}
vec3 rdr2(vec2 uv)
{
  vec2 dir = normalize(vec2(1.));
  float str = 0.01*sin(uv.y*5.+_time*10.);
  vec3 col;
  col.r = rdr3(uv+dir*str).r;
  col.g = rdr3(uv).g;
  col.b = rdr3(uv-dir*str).b;
  return col;
}

void main(void)
{
  _time = fGlobalTime;
  vec2 uv = (gl_FragCoord.xy-vec2(.5)*v2Resolution.xy)/v2Resolution.xx;
  
  vec3 col = rdr2(uv);
  out_color = vec4(col, 1.);
}
