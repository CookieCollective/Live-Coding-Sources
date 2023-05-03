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

uniform sampler2D backbuffer;

uniform sampler2D greyNoise;

float mtime; // modulated time

#define FFTI(a) time

#define sat(a) clamp(a, 0., 1.)
#define FFT(a) texture2D(spectrum, vec2(a, 0.)).x

#define EPS vec2(0.01, 0.)

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
    vec2 acc = vec2(10000., -1.);

    p.xy *= r2d(sin(time*.3)*.5);

    vec3 pt = p+vec3(0., 0., time);
    vec3 opt = pt;
    vec3 repl = vec3(5.,5.,10.);
    pt = mod(pt+repl*.5,repl)-repl*.5;
    float tube = length(pt.xy)-.1;
    tube = max(tube, sin(pt.z+time*70.));
    tube = max(tube, -(length(opt.xy)-25.));
    acc = _min(acc, vec2(tube, 2.));


    vec3 pc = p+vec3(sin(time)*vec3(1.,2.,3.))+vec3(0.,0.,time*100.);
    vec3 repc = vec3(20.);
    vec3 idc = floor((pc+repc*.5)/repc);
    pc = mod(pc+repc*.5,repc)-repc*.5;
    pc.xy *= r2d(pc.z);

    float cucu = _cucube(pc, vec3(1.), vec3(.01));
    // oui ma variable s'appelle cucu et alors ?
    cucu = length(pc.xz)-.5;
    cucu = max(cucu, -(length(pc.xz)-2.));
    acc = _min(acc, vec2(cucu, 2.));

    p += vec3(sin(time), -3.+cos(time*.33), 0.);
    vec3 pu = p;
    pu.y = abs(pu.y);
    pu.y += 2.2;
    float ufo = length(pu)-3.;
    acc = _min(acc, vec2(ufo, 0.));

    float glass = length(p-vec3(0.,-.5,0.))-.7;
    acc = _min(acc, vec2(glass, 1.));

    vec3 pl = p-vec3(0.,-.3,0.);
    float an = atan(pl.z, pl.x)+time;
    float repa = PI*2./12.;

    float sector = mod(an+repa*.5,repa)-repa*.5;
    pl.xz = vec2(sin(sector), cos(sector))*length(pl.xz);
    float light = length(pl-vec3(0.,0.,1.8))-.2;
    acc = _min(acc, vec2(light, 2.));

    return acc;
}


vec3 accCol;
vec3 trace(vec3 ro, vec3 rd)
{
    accCol = vec3(0.);
    vec3 p = ro;
    for (int i = 0; i < 32; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
          return vec3(res.x, distance(p, ro), res.y);
        accCol += vec3(.5,.2,.9)*(1.-sat(res.x/2.5))*.05;
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
    col *= .5;
  }
  if (res.z == 2.)
  {
    col = vec3(1.);
  }
  if (res.z == 3.)
  {
    col = vec3(0.1);
  }
  return col;
}

vec3 rdrenv(vec3 rd)
{
  float an2 = atan(rd.y, rd.x);
  float repb = PI*2./12.;
  float sector = mod(an2+repb*.5,repb)-repb*.5;
  rd.xy = vec2(sin(sector), cos(sector))*length(rd.xy);


  rd *= .5;
  float an = atan(rd.y, rd.x);
  vec3 col = vec3(1.)*FFT(abs(rd.x*length(rd.xy))*2.)*1.;
  col += .2*vec3(1.)*sin(an*100.)*sat(sin(length(rd.xy)*100.-time*30.));

  return .1*col * vec3(sin(time)*.3+.7, .5,length(rd.xy))*(1.-sat(length(rd.xy)*1.5));
}

vec3 rdr(vec2 uv)
{
  uv *= r2d(time*.13);
    vec3 ro = vec3(2, 0., -10.);
    vec3 ta = vec3(0.,0.,0.);
    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    vec3 col = vec3(0.);


    uv.x -= sign(uv.x)*abs(uv.y*.5);
    col = rdrenv(rd);

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
            vec3 refl = normalize(reflect(rd, n));
            if (res.z == 1.)
              col += rdrenv(refl);
          }
        }
    }
    col += accCol*FFT(.1)*5.;

    return col;
}
vec3 dunno(vec2 uv, vec3 col)
{
  uv *= r2d(sin(length(uv)*3.+time*.2));
  float an = atan(uv.y, uv.x);
  float repa = PI*2./12.;
  float id = floor((an+repa*.5)/repa);
  float sector = mod(an+repa*.5,repa)-repa*.5;
  uv = vec2(sin(sector), cos(sector))*length(uv);
  vec2 nuv = uv-vec2(0.,.5+.1*sin(time*.5+id));
  float body = _sqr(nuv, vec2(.05,.2));
  nuv.x = abs(nuv.x);
  float eye = length((nuv-vec2(.02, -0.15))/vec2(1.,abs(sin(time*4.+id))))-.01;

  col = mix(col, vec3(0.), 1.-sat(body*400.));
  col = mix(col, vec3(0.,1.,1.), 1.-sat(eye*400.));
  return col;
}

void main() {
  vec2 ouv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.xx;
    _seed = time+length(uv)+uv.x*10.+hash11(uv.y);
    uv += (vec2(rand(), rand())-.5)*.05*sat(length(uv)-.15);
    vec3 col = rdr(uv);
    col = dunno(uv, col);
    col *= (1.-sat(length(uv)*2.));
    col *= 2.;
//    col *= 1.-sat((abs(uv.x)-.0)*100.);
    col = mix(col, texture2D(backbuffer, ouv).xyz, 0.5);
    gl_FragColor = vec4(col, 1.0);
}
