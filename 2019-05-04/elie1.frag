precision mediump float;
uniform vec2 resolution;
uniform float time;
uniform sampler2D backbuffer;

float sat(float x) { return clamp(x,0.,1.); }

const float bpm = 80.;

mat2 rot(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float sc(vec3 p, vec2 uuv) {

  p.xy *= rot(time);

  float bt = pow(1.-fract(.0+time*bpm/60.), 4.);
  float bt2 = pow(1.-fract(.0+time*bpm/60.), .5);
  float r = mix(.1, .3, bt);

  float a = atan(uuv.y, uuv.x);
  r += (sin(a * 10.) * bt2 * .5+.5) * .1;

  r *= 0.5;

  vec3 id = floor(p*2.);
  p = (fract(p*2.)-.5)/2.;
  r *= 1./length(dot(id,vec3(.9)));
  return length(p) - r;
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
    if (s < 0.01) break;
    p += s * d;
    off = i;
  }

  off *= 1.9;

  float t0 = 1447.259;
  float t1 = t0 + 5.;
  float fac = mix(.2,.8,sat(smoothstep(t0,t1,time)));
  vec3 col = .5+vec3(.5,.5,.5)*cos(6.28*(vec3(.1,time*.1,.6) + uv.x + off + time*.1));

  //col *= smoothstep(0.,.01,);

  gl_FragColor = mix(texture2D(backbuffer, gl_FragCoord.xy/resolution), vec4(col, 1.0), .2);
}
