/*{"audio":true, "midi": true}*/
precision mediump float;
uniform vec2 resolution;
uniform float time;
uniform sampler2D backbuffer;
uniform float volume;
uniform sampler2D midi;

float sat(float x) { return clamp(x,0.,1.); }

const float bpm = 75.*1.;

mat2 rot(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float sc(vec3 p, vec2 uuv) {

  p.yx *= rot(time*.5);
  p.yz *= rot(time*.1);

  float bt = pow(1.-fract(.4+time*bpm/60.), 4.);
  float bt2 = pow(1.-fract(.4+time*bpm/60.), .5);
  float r = mix(.1, .3, bt);

  p.xy *= rot((abs(bt2-.5)+.5) * .1);

  float a = atan(uuv.y, uuv.x);
  r += (sin(a * 10.) * bt2 * .5+.5) * .1;
  //r += (sin(a * 50.) * bt2 * .5+.5) * 1.2 * volume;

  r *= 0.5;

  vec3 id = floor(p*2.);
  p = (fract(p*2.)-.5)/2.;
  float r2 = r;
  //r *= 1./(.1+length(dot(id,vec3(1.5))));
  vec3 p2 = p;
  //p2.xy = rot(time + p2.z*10.)*p2.xy;
  //p2.x += uuv.x*.1;
  p.xz = rot(bt) * p.xz;
  p.y += atan(p.z)*.1;

  p *=10.1;

  float md3 = texture2D(midi, vec2(.69, .47), 0.).x;
  p.xy = rot(md3) * p.xy*3.;

  //p -= .5;
  float box = max(p.x, max(p.y, p.z));
  return box;
  return min(length(p) - r, max(length(p2.xz) - r2*5.5, abs(p.z-4.)-3.));
}

void main() {
  vec2 uv = (gl_FragCoord.xy/resolution);
  vec2 uuv = (gl_FragCoord.xy * 2. - resolution) / max(resolution.x, resolution.y);
  vec3 p = vec3(0.,0.,-1.);
  vec3 d = vec3(uuv, 1.0);
  float off = 0.;
  float s;

  for (float i = 0.; i < 1. ; i += .01) {
    s = sc(p, uuv);
    if (s < 0.001) break;
    p += s * d;
    off = i;
  }

  off *= 2.5;

  float t0 = 2755.312;
  float t1 = t0 + 10.;
  float fac = mix(.2,.5,sat(smoothstep(t0,t1,time)));
  vec3 col = vec3(.7,.5,.3)+vec3(.5,fac,.5)*cos(6.28*(vec3(.1,.3,.4) + uv.x + off + time*.1));

  //col *= smoothstep(0.,.01,);
  float bt = pow(1.-fract(.2+time*bpm/60.), 4.);
  float f = texture2D(midi, vec2(1./90.,1.), 0.).r;

  float md1 = texture2D(midi, vec2(.69, .48), 0.).x;
  float md2 = texture2D(midi, vec2(.69, .49), 0.).x;

  vec2 uuv2 = uuv;

  uuv = rot(time*.2+pow(length(uuv)*.5,5.)*53.) * uuv;
  uuv = fract(uuv*2.)-.5;
  vec2 idx = floor(uuv*2.);

  float rad = mix(.4,mix(.1,.8,md1),bt);

  rad += abs(idx.x)*.0;

  float st = 24.*md2;
  rad += pow(sin((atan(uuv.y, uuv.x)+.5*time)*st)*.5+.5, 10.)*bt*.3;
  rad -= pow(sin((atan(uuv.y, uuv.x)+3.1415+.5*time)*st)*.5+.5, 1.)*bt*.1;

  rad += pow(sin((atan(uuv.y, uuv.x)+1.*time)*st*10.)*.5+.5, 10.)*bt*.1;

 float dd = length(uuv)-rad;

  dd = max(dd, -(length(uuv)-rad*.5));

  col *= mix(1., smoothstep(.0,.005, dd), md1*2.);

  t0 = 5781.261;
  t1 = t0 + 10.;
  fac = mix(1.,-1.,sat(smoothstep(t0,t1,time)));
  col = mix(col, vec3(col.r), smoothstep(.0,.005,uuv2.x+fac));

  gl_FragColor = mix(texture2D(backbuffer, gl_FragCoord.xy/resolution), vec4(col, 1.0), .3);
}
