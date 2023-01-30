precision highp float;

uniform float time;
uniform vec2 resolution;
uniform sampler2D spectrum;
uniform sampler2D midi;

uniform sampler2D greyTex;
uniform sampler2D cookieTex;
uniform sampler2D ziconTex;

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
float hash(float seed)
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
    return hash(_seed);
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

vec2 map(vec3 p)
{
    vec2 acc = vec2(10000., -1.);

    acc = _min(acc, vec2(length(p)-1., 0.));

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

vec3 getMat(vec3 p, vec3 n, vec3 rd, vec3 res, vec2 id)
{
  vec3 col = n *.5+.5;

  vec3 ldir = normalize(vec3(1.));

  if (res.z == 0.)
  {

    col = vec3(.3,.1,.1)+mix(vec3(1.), vec3(.5,.6,.3), .5)*sat(dot(-rd, n));
    vec3 p2 = p;
    float speed = 2.;
    float it = float(int(time));
    float t=time*2.+length(id);
    float hangle = clamp(sin(t)*2., -1.,1.);
    p2.xz *= r2d((smoothstep(-1.,1.,hangle)-.5));
    p2.yz *= r2d(sin(t*.3)*.5);
    vec2 uv = p2.xy;
    float border = abs(length(uv)-.4)-.2+.1*sin(time);
    float eyemask = length(uv)-.5;
    border = max(border, eyemask);
    col = mix(col, vec3(0.), 1.-sat(eyemask*400.));
    float an = atan(uv.y, uv.x);
    vec2 uvi = vec2(an*.1, .05*length(uv));
    vec3 rgb = vec3(0.);
    vec3 iriscol = mix(vec3(0.,.4,.2), vec3(0.,0.5,0.8), textureRepeat(greyTex, uvi).x);
    iriscol.yz *= r2d(textureRepeat(greyTex, id*.1).x*15.+time);
    iriscol = abs(iriscol.zxy);
    rgb = iriscol
    *(pow(textureRepeat(greyTex, uvi*.5).x, 2.)+.5)
    *pow(sat(-dot(rd, n)), 2.);

    col = mix(col, rgb, 1.-sat(border*400.));
vec3 h = normalize(rd+ldir);
    col += vec3(.2)*pow(sat(-dot(h, n)), 45.);
  }

  return col;
}

vec3 rdrback(vec2 uv)
{
    vec2 ouv = uv;
  vec3 col = vec3(0.);
  float t = time*.1;
  uv += vec2(sin(t), cos(t))*.25;
  vec2 uv2 = vec2(atan(uv.y, uv.x)/PI, length(uv))*.25;
  col = pow(textureRepeat(greyTex, uv2+vec2(0., -time*.125)).xxx, vec3(6.))*.45*vec3(.9,.2,.1);
  col += vec3(.1,.2,.5)*pow(textureRepeat(greyTex, uv2*.5+vec2(0., -time*.0125)).xxx, vec3(16.))*.45;
  col.xy *= r2d(time+13.*length(uv));
  col = abs(col);
  col *= 1.5;
  return col.zxy*sat(length(ouv)*5.);
}

vec3 rdr(vec2 uv)
{
  uv *= r2d(.5);
  vec2 rep = vec2(.25);
  vec2 id = floor((uv+rep*.5)/rep);
  uv = mod(uv+rep*.5,rep)-rep*.5;
  uv *= 1.-.2*sin(length(id)*10.+time);
    vec3 ro = vec3(0.,0., -5.);
    vec3 ta = vec3(sin(time*.5+id.y*3.)*.5,sin(time*.25+id.x*2.)*.5,0.);
    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    vec3 col = vec3(0.);



    col = rdrback(uv);


    vec3 res = trace(ro, rd);
    float depth = 100.;
    if (res.y > 0.)
    {
      depth = res.y;
        vec3 p = ro + rd*res.y;
        vec3 n = getNorm(p, res.x);
        col = getMat(p, n, rd, res, id);

        float spec = .1;
        vec3 refl = normalize(reflect(rd, n)+spec*(vec3(rand(), rand(), rand())-.5));
        vec3 resrefl = trace(p+n*0.01, refl);
    }

    return col;
}
uniform sampler2D backbuffer;
void main() {
  vec2 ouv = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.xx;
    //uv *= vec2(.66, 1.);
    //uv -= vec2(.1,0.);
    uv *= 1.+length(uv)*5.;
    uv *= 1.;
    _seed = time+textureRepeat(greyTex, uv).x;
   vec3 col = rdr(uv);
   col += pow(rdr(uv+(vec2(rand(), rand())-.5)*.05), vec3(2.));
   col = sat(col);
   col *= (1.-sat((length(uv)-.5)*2.));
   col = mix(col, texture2D(backbuffer, ouv).xyz, .75);
//   col += texture2D(ziconTex, (uv*4.+.5)).xyz;
    gl_FragColor = vec4(col, 1.0);
}
