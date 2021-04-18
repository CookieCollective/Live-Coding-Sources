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

float _sqr(vec2 uv, vec2 s)
{
  vec2 l = abs(uv)-s;
  return max(l.x,l.y);
}
float _time;
mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c);}

vec4 map2d(vec2 p)
{
  float acc = 100.;
  vec3 col;
  for (int i = 0; i < 15; ++i)
  {
    float th = 0.01+0.01*float(i);
    
    float sqr = abs(_sqr(p*r2d(sin(float(i)+_time*.5)), vec2(.05)*float(i+.5)))-th;
    if (sqr < 0.)
    {
      
      if (i == 0)
        col = vec3(1.,1.,1.);
      if (i == 1)
        col = vec3(1.,.5,0.5); 
      if (i == 2)
        col = vec3(1.,.5,0.8); 
      if (i == 3)
        col = mix(vec3(.5), vec3(1.,.9,0.8), sat(sin((p.x+p.y)*155.+_time)*50.)); 
    }
    acc = min(acc, sqr);
  }
  return vec4(acc, col);
}

vec3 getCam(vec3 rd, vec2 uv)
{
  float fov = 1.;
  vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
  vec3 u = normalize(cross(rd, r));
  return normalize(rd+fov*(r*uv.x+u*uv.y));
}
float _cube(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
  l.xy *= r2d(_time);
  l = abs(l)-s;
  l.xz *= r2d(_time);
  return max(l.x, max(l.y,l.z));
}
vec2 map(vec3 p)
{
  p.xy *= r2d(_time);
  p.xz *= r2d(_time*.5);
  vec2 cube = vec2(_cube(p, vec3(.5)), 0.);
  return cube;
}

vec3 trace(vec3 ro, vec3 rd, int steps)
{
  vec3 p = ro;
  for (int i = 0; i< steps;++i)
  {
    vec2 res = map(p);
    if (res.x < 0.01)
      return vec3(res.x, distance(p, ro), res.y);
  p += rd*res.x;
    }
  return vec3(-1.);
}

vec3 norm(float d, vec3 p)
{
  vec2 e = vec2(0.01,0.);
  return normalize(vec3(d)-vec3(map(p+e.xyy).x, map(p+e.yxy).x, map(p+e.yyx).x));
}

vec3 rdr(vec2 uv)
{
  float shp = 400.;
  vec3 col = vec3(.1)+texture(texTex2, uv).xxx*.1;
  vec4 res = map2d(uv*2.);
  col = mix(col, res.yzw, 1.-sat(shp*res.x));
  
  vec3 ro = vec3(0.,0.,-5.);
  vec3 ta = vec3(0.,0.,0.);
  vec3 rd = normalize(ta-ro);
  
  rd = getCam(rd, uv);
  vec3 r = trace(ro,rd,256);
  if (r.y > 0.)
  {
    vec3 p = ro +rd*res.y;
    vec3 n = norm(res.x, p);
    
    col += mix(vec3(1.,.5,.25), vec3(p.xzy), p.x);
  }
  
  return col;
}

void main(void)
{
  _time = fGlobalTime;
  vec2 uv = (gl_FragCoord.xy-vec2(.5)*v2Resolution.xy)/v2Resolution.xx;
  vec3 col;
  col = rdr(uv);
  col = rdr(uv*.5)*.5;
  col = rdr(uv*vec2(-1.,1.)*2.*mix(1.,1.5,mod(_time, 1.5)));
  out_color = vec4(col, 1.);
}
