#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define sat(a) clamp(a, 0., 1.)

mat2 r2d(float a) { float c = cos(a); float s = sin(a); return mat2(c, -s, s, c); }

vec3 getCam(vec3 rd, vec2 uv)
{
  float fov = 1.;
  vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
  vec3 u = normalize(cross(rd, r));
  return normalize(rd+(r*uv.x+u*uv.y)*fov);
}

vec2 _min(vec2 a, vec2 b)
{
  if (a.x < b.x)
    return a;
  return b;
}

float _cube(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
    l.xz *= r2d(fGlobalTime*.1);
  l+= vec3(.5,0.1,0.);
    l.xy *= r2d(fGlobalTime*.1+sin(p.x));
  l = abs(l)-.5;


  return max(l.x, max(l.y, l.z));
}

vec3 accCol;

vec2 map(vec3 p)
{
  p.xy *= r2d(fGlobalTime*.25);
  p.xz *= r2d(fGlobalTime*.25);
  float acc = 1000.;
  
  for (int i = 0; i < 16; ++i)
  {
    float fi = float(i)*.25;
    vec3 pc = p;
    float r = 5.;
    pc.x += sin(fGlobalTime*.25+fi*3.3)*r;
    pc.y += cos(fGlobalTime*.5+fi*2.)*r;
    pc.z += abs(sin(fGlobalTime*.1+fi*2.));
    pc.xy *= r2d(fGlobalTime+fi);
    pc.xz *= r2d(fGlobalTime*.5+fi*2.);
    acc = min(acc, _cube(pc, fi+vec3(5.5)*sin(fi+fGlobalTime)));
  }  
  vec2 main = vec2(_cube(p, vec3(.5)),0.);
  return _min(main, vec2(acc, 1.));
}

vec3 getNorm(float d, vec3 p)
{
  //return normalize(cross(dFdx(p), dFdy(p)));
  vec2 e = vec2(0.01,0.);
  return normalize(vec3(d)-vec3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x));
}

vec3 trace(vec3 ro, vec3 rd, int steps)
{
  accCol = vec3(0.);
  vec3 p = ro;
  for (int i = 0; i < steps; ++i)
  {
    float fi = float(i);
    vec2 res = map(p);
    if (res.x < 0.01)
    {
        return vec3(res.x, distance(p, ro), res.y);
    }
   
    vec3 rgb = vec3(1.);
     if (res.y == 1.)
       rgb = vec3(1.,.5,.25);
      accCol += rgb*(rd+.5)*vec3(sin(fi)*.5+.5, cos(fi)*.5+.5,.5)*pow(1.-sat(res.x/0.75),2.)*.15;
     
    p += rd * res.x;
  }
  return vec3(-1.);
}

vec3 rdr(vec2 uv)
{


  vec3 ro = vec3(sin(fGlobalTime*.25),5.*sin(fGlobalTime),-15.*cos(fGlobalTime));
  vec3 ta = vec3(0.,0.,0.);
  vec3 rd = normalize(ta-ro);
    vec3 col = pow(texture(texNoise, uv*5.).x, 9.)*vec3(150.)+mix(vec3(.5,.5,.6)*.25, vec3(.95,.56,.34), (1.-sat(abs(uv.y*5.)))*sat(length(uv)));
  rd = getCam(rd, uv);
  vec3 res = trace(ro, rd, 32);
  if (res.y > 0.)
  {
      vec3 p = ro + rd * res.y;
      vec3 n  = getNorm(res.x, p);
      col = n * .5 + .5;
    if (res.z == 1.)
    {
      col = vec3(.25);
      col += vec3(.75,0.2,.14)*pow(sat(-dot(rd, n)),5.);
      if (res.z == 0.)
        col = vec3(0.);
    }
  }
  col += accCol.zxy;
  return col;
}

vec3 rdr2(vec2 uv)
{
  vec2 dir = normalize(vec2(1.));
  float strength = .01;
  vec3 col = vec3(0.);
  col.r = rdr(uv+strength*dir).x;
  col.g = rdr(uv).y;
  col.b = rdr(uv-strength*dir).z;
  return col;
}

void main(void)
{
	vec2 uv = (gl_FragCoord.xy-vec2(.5)*v2Resolution.xy)/v2Resolution.xx;

  /*
	float f = texture( texFFT, d ).r * 100;
	m.x += sin( fGlobalTime ) * 0.1;
	m.y += fGlobalTime * 0.25;
*/
    vec3 col = vec3(0.);
    col = rdr2(uv)*.5;
  
  float stp = 0.025;
  uv = floor(uv/stp)*stp;
  col = mix(rdr(uv), col, 1.-sat(length(uv*2.))*sat(abs(uv.y*3.)));
  col += (1.-sat(length(uv*2.)))*vec3(.1,.2,.3)*5.*(sat((abs(sin((uv.x+uv.y)*5.+fGlobalTime))-.95)*400.));
		out_color = vec4(col, 1.);
}