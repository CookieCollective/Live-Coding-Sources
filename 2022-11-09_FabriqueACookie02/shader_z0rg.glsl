/*{ "camera": true }*/
uniform sampler2D camera;
uniform sampler2D backbuffer;
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
    return normalize(rd+(r*uv.x+u*uv.y)*3.);
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


    float gnd = -p.y+2.;
    acc = _min(acc, vec2(gnd, 2.));
//    acc = _min(acc, vec2(length(p+vec3(0.,0.,-4.))-1., 0.));

    float ceili = p.y+2.;
    acc = _min(acc, vec2(ceili, 1.));

vec2 rep = vec2(7.);
p.z+=time;
p.xz = mod(p.xz+rep*.5,rep)-rep*.5;

float cyl = length(p.xz)-.5;
acc = _min(acc, vec2(cyl, 3.));
    return acc;
}


vec3 accCol;
vec3 trace(vec3 ro, vec3 rd)
{
    accCol = vec3(0.);
    vec3 p = ro;
    for (int i = 0; i < 128; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
            return vec3(res.x, distance(p, ro), res.y);
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
    col = vec3(.1);
    vec2 uvp = p.xz+vec2(0.,time*2.);
    vec2 rep = vec2(1.5);
    vec2 id = floor((uvp+rep*.5)/rep);
    uvp = mod(uvp+rep*.5,rep)-rep*.5;
    float dott = length(uvp)-.3;
    vec3 rgb = mix(vec3(1.,0.,0.), vec3(1.), sat(sin(length(id)-time)));
    float sampl = textureRepeat(greyNoise, id*.1).x;
    rgb *= pow(sampl,5.);
    rgb *= mod(sampl+time, 1.)
;    col = mix(vec3(0.), rgb*10., 1.-sat(dott*400.));
  }
  if (res.z == 2.)
  {
    col = vec3(0.);
    vec2 uvp2 = p.xz+vec2(0.,-2.*time);
    vec2 grid = sin(uvp2*5.)+.99;
    col = vec3(.1,.2,.9)*(1.-sat(min(grid.x,grid.y)*100.));
  }
  if (res.z == 3.)
    col = vec3(0.);
  return col;
}
vec3 rdr(vec2 uv)
{
  uv *= r2d(sin(time*.5)*.25);
  float d = 5.;
  float t = time*.13*0.+.5;
    vec3 ro = vec3(sin(t)*d, 0., cos(t)*d);
    vec3 ta = vec3(0.,0.,0.);
    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    vec3 col = vec3(0.);

    vec3 res = trace(ro, rd);
    float depth = 100.;
    if (res.y > 0.)
    {
      depth = res.y;
        vec3 p = ro + rd*res.y;
        vec3 n = getNorm(p, res.x);
        col = getMat(p, n, rd, res);
        vec3 refl = normalize(reflect(rd, n)+(vec3(rand(), rand(), rand())-.5)*.02);
        vec3 resrefl = trace(p+n*.005, refl);
        if (resrefl.y > 0.)
        {
          vec3 prefl = p+refl*resrefl.y;
          vec3 nrefl = getNorm(prefl, resrefl.x);
          col += getMat(prefl, nrefl, refl, resrefl);
        }
    }
    col = mix(col, vec3(.1,.2,.4)*3., 1.-exp(-depth*0.01));
    return col;
}
void main() {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.xx;
    vec2 ouv = gl_FragCoord.xy/resolution.xy;
    float pix = .02;
    vec2 uv2 = floor(uv/pix)*pix;
    _seed = time+textureRepeat(greyNoise, uv).x;
   vec3 col = rdr(uv);
   for (float i = 0.; i < 8.; ++i)
   {
     vec2 off = +(vec2(rand(), rand())-.5)*.02;
     col += rdr(uv+off)/(8.*length(off)/0.01);
   }
   //col = texture2D(camera, uv*10.).xyz;
//vec3 col = vec3(0.,0.,.5
col = mix(col, rdr(uv2), sat(length(uv)*2.));
col *= 1.-sat(lenny(uv));
float shape = abs(uv.x)-.2;
col = mix(col, col.xxx, sat(shape*400.));

vec2 uva = vec2(atan(uv.y, uv.x)*.5, length(uv)*.2-time);
col += pow(textureRepeat(greyNoise, uva*.5).x, 2.)*vec3(.2,.4,.9)*.5;

col = mix(col, texture2D(backbuffer, ouv).xyz, .8);
    gl_FragColor = vec4(col, 1.0);
}
