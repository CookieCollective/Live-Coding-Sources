/*{ "camera": true,
"audio":true }*/
uniform sampler2D camera;

#ifndef TOOLS_INCLUDE
#define TOOLS_INCLUDE

precision highp float;

uniform float time;
uniform vec2 resolution;
uniform sampler2D spectrum;
uniform sampler2D midi;

uniform sampler2D greyNoise;

float mtime; // modulated time

#define FFTI(a) time

#define sat(a) clamp(a, 0., 1.)
#define FFT(a) texture2D(spectrum, vec2(a, 0.)).x

#define EPS vec2(0.01, 0.)
#define AKAI_KNOB(a) (texture2D(midi, vec2(176. / 256., (0.+min(max(float(a), 0.), 7.)) / 128.)).x)

#define MIDI_KNOB(a) (texture2D(midi, vec2(176. / 256., (16.+min(max(float(a), 0.), 7.)) / 128.)).x)
#define MIDI_FADER(a) (texture2D(midi, vec2(176. / 256., (0.+min(max(float(a), 0.), 7.)) / 128.)).x)

#define MIDI_BTN_S(a) sat(texture2D(midi, vec2(176. /  256., (32.+min(max(float(a), 0.), 7.)) / 128.)).x*10.)
#define MIDI_BTN_M(a) sat(texture2D(midi, vec2(176. / 256., (48.+min(max(float(a), 0.), 7.)) / 128.)).x*10.)
#define MIDI_BTN_R(a) sat(texture2D(midi, vec2(176. / 256., (64.+min(max(float(a), 0.), 7.)) / 128.)).x*10.)

#define FFTlow (FFT(0.1) * MIDI_KNOB(0))
#define FFTmid (FFT(0.5) * MIDI_KNOB(1))
#define FFThigh (FFT(0.7) * MIDI_KNOB(2))
#define PI 3.14159265
#define TAU (PI*2.0)
float hash11(float seed)
{
    return fract(sin(seed*123.456)*123.456);
}

float _cube(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
  return max(l.x, max(l.y, l.z));
}
float _cucube(vec3 p, vec3 s, vec3 th)
{
    vec3 l = abs(p)-s;
    float cube = max(max(l.x, l.y), l.z);
    l = abs(l)-th;
    float x = max(l.y, l.z);
    float y = max(l.x, l.z);
    float z = max(l.x, l.y);

    return max(min(min(x, y), z), cube);
}
float _seed;

float rand()
{
    _seed++;
    return hash11(_seed);
}

mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

vec3 getCam(vec3 rd, vec2 uv)
{
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    return normalize(rd+(r*uv.x+u*uv.y)*2.);
}

float lenny(vec2 v)
{
    return abs(v.x)+abs(v.y);
}
float _sqr(vec2 p, vec2 s)
{
    vec2 l = abs(p)-s;
    return max(l.x, l.y);
}
float _cir(vec2 uv, float sz)
{
  return length(uv)-sz;
}

float _loz(vec2 uv,float sz)
{
  return lenny(uv)-sz;
}
vec2 _min(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}
vec2 _max(vec2 a, vec2 b)
{
  if (a.x > b.x)
      return a;
  return b;
}

// To replace missing behavior in veda
vec4 textureRepeat(sampler2D sampler, vec2 uv)
{
  return texture2D(sampler, mod(uv, vec2(1.)));
}

#endif // !TOOLS_INCLUDE



vec2 map(vec3 p)
{
    float pix = .2;
    p = floor(p/pix)*pix;
    vec2 acc = vec2(10000., -1.);

    //acc = _min(acc, vec2(length(p)-1., 0.));
    vec3 pc = p;
    pc.xz *= r2d(time*.1+p.y*.005);
    vec2 repc=vec2(40.5);
    pc.xz = mod(pc.xz+repc*.5,repc)-repc*.5;

    float col = length(pc.xz)-.5;
    col = max(col, _sqr(p.xz, vec2(70.)));
    acc = _min(acc, vec2(col, 1.));

    vec3 pp = p;
    pp.xy *= r2d(sin(pp.z+time));
    float an = atan(pp.y, pp.x);
    float rep = PI*2./3.;
    float sector = mod(an+rep*.5,rep)-rep*.5;
    pp.xy = vec2(sin(sector), cos(sector))*length(p.xy);
    float pillar = _sqr(pp.xy-vec2(0.,.5+FFT(sin(pp.z)*.25)), vec2(.07));
    acc = _min(acc, vec2(pillar, 2.));

    vec3 ps = pc;
//    ps.xy *= r2d()
    float repa = 1.5;
    float ida = floor((ps.y+repa*.5)/repa);
    ps.y = mod(ps.y+repa*.5,repa)-repa*.5;
    ps.xz *= r2d(ida+sin(time*.5));
    float sz = 1.+.3*sin(ida*2.+time*2.)
    +.25*sin(ida*2.+time*4.)
    +FFT(abs(ida*.1)*.5);
    float sq = _sqr(ps.xz, vec2(sz));
    sq = max(abs(sq)-.05, abs(ps.y)-.4);
    acc = _min(acc, vec2(sq, 3.));
    return acc;
}


vec3 accCol;
vec3 trace(vec3 ro, vec3 rd)
{
    accCol = vec3(0.);
    vec3 p = ro;
    for (int i = 0; i < 100; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
          return vec3(res.x, distance(p, ro), res.y);
          accCol += sat(sin(p))*(1.-sat(res.x/1.5))*.1;
        p+= rd*res.x;
    }
    return vec3(-1.);
}

vec3 getNorm(vec3 p, float d)
{
  vec2 e = vec2(0.01, 0.);
  return  normalize(vec3(d) - vec3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x));
}
vec3 getMat(vec3 p, vec3 n, vec3 rd, vec3 res)
{
  vec3 col = n*.5+.5;

  if (res.z == 1.)
  {
    vec3 a = vec3(1.,.1,.2)*1.5;
    vec3 b = vec3(1.,.1,.2)*3.5;
    col = mix(a, b, (sin(p.y+time*13.)));
    col.xy *= r2d(p.x+time);
    col = abs(col);
  }
  if (res.z == 2.)
  {
    col = vec3(1.)*(1.-sat(res.y/10.));
  }
  if (res.z == 3.)
  {
    col = vec3(0.1);
  }
  return col;
}
vec3 rdr(vec2 uv)
{
  uv *= r2d(.5+time*.1);
    vec3 ro = vec3(0, 0., -3.);
    vec3 ta = vec3(0.,6.*sin(time*.05),0.);
    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    vec3 col = vec3(0.);
    uv.x -= sign(uv.x)*abs(uv.y*.5);
    col = vec3(1.)*FFT(abs(uv.x)*2.)*1.;

    vec3 res = trace(ro, rd);
    vec3 acc = accCol;
    if (res.y > 0.)
    {
        vec3 p = ro + rd*res.y;
        vec3 n = getNorm(p, res.x);
        col = getMat(p, n, rd, res);
        if (res.z == 3.)
        {
          vec3 refl = normalize(reflect(rd, n)
          +(vec3(rand(), rand(), rand())-.5)*.0);
          vec3 resrefl = trace(p+n*0.01, refl);
          if (resrefl.y > 0.)
          {
            vec3 prefl = p+n*0.01+refl*resrefl.y;
            vec3 nrefl = getNorm(prefl, resrefl.x);
            col += getMat(prefl, nrefl, refl, resrefl);
          }
        }
    }
    col += acc;
    return col;
}

#define repeat(p,r) (mod(p,r)-r/2.)
float sdf(vec3 p)
{
  vec3 q = p;
  //  p.z -= time * 2.;
    //p.z = repeat(p.z, 9.);
    float t = time*4.+p.z*.4;
    t = pow(fract(t), .1) + floor(t);
      p.xz *= r2d(t);
        p.yz *= r2d(t);
  float dist = 100.;
  const float count = 8.;
  float a = 1.;
  float r = .3+.0*abs(sin(time*5.));
  // r = fract(time*1.+p.z)*.3;
  float s = .2+.1*abs(sin(time*10.));
  for (float i = 0.; i < count; ++i)
  {
    p.x = abs(p.x)-r*a;
    p.xy *= r2d(t/a);
    p.xz *= r2d(t/a);
    dist = min(dist, length(p)-s*a);
  // dist = min(dist, abs(max(p.x,max(p.y,p.z)))-.1*a);
    a/=1.4;
  }
//dist = max((dist), -(length(q)-0.3));
//dist = max(abs(dist)-.01, q.z);
  return dist;
}
void main() {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.xx;
    //_seed = time+length(uv)+uv.x*10.+hash11(uv.y);
    //uv += (vec2(rand(), rand())-.5)*.0;

    vec3 pos = vec3(0,0,3);
    vec3 ray = normalize(vec3(uv,-.5));
    const float count = 30.;
    float shade = 0.;
    for (float i = count; i > 0.; --i)
    {
      float dist = sdf(pos);
      if (dist<.001)
      {
        shade = i/count;
        break;
      }
      pos += ray * dist;
    }
//    uv = abs(uv);
   vec3 col = vec3(shade);
  // col = pow(col, vec3(2.2));
   //col += pow(rdr(uv+(vec2(rand(), rand())-.5)*.2),vec3(2.))*.1;
   //col = texture2D(camera, uv*10.).xyz;
//vec3 col = vec3(0.,0.,.5);
//col += rand()*.1;
//col *= 1.-sat((length(uv)-.2)*3.);
col = 0.5 + 0.5 * cos(vec3(1,2,3)*4. + pos.z + shade * 1.);
    gl_FragColor = vec4(col*shade, 1.0);
}
