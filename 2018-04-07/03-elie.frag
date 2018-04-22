/*
{"IMPORTED": {
    "guinness": {
      "PATH": "./guinness.png",
    },
  },
  "pixelRatio": 1,
  "audio": true,
  "camera": false,
  "keyboard": true,
  "midi": true,
}
*/
precision mediump float;

uniform float time;
uniform vec2 resolution;
uniform sampler2D camera;
uniform sampler2D key;
uniform sampler2D samples;
uniform sampler2D spetrum;

uniform sampler2D guinness;

mat2 rot(float a)
{
  float c = cos(a), s = sin(a);
  return mat2(c, s, -s, c);
}

struct D {
  float d;
  vec3 c;
};

D map(vec3 p){
  p.xy *= rot(time * .3 + p.z * .01);
  p.yz *= rot(time * .5);
  D d;
  d.d= length(p.xz) - 0.5;
  d.c=vec3(1);

  float t = time * 0.01;
  float t2 = time * 1.;
  p.yz *= sin(exp((sin(t2) * sin(t2) + sin(t2 * 1.41) * sin(t2 * 1.41)) * 0.5) * 0.2 * p.x);

  for (float z = 0. ; z < 5. ; z += 1.) {
    float c = cos(t + 0.1 + z * 0.2);
    float s = sin(t + 0.1 + z * 0.2);
    p.xy *= mat2(c, s, -s, c);
    d.d = min(d.d, length(p.yz) - 0.5);
  }


  return d;
}

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
  return a+b*cos(6.2831*(c*t+d));
}

void main () {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro=vec3(0,0,-8),
      rd=normalize(vec3(uv,1.-length(uv*.5))),
      mp=ro + rd * 6.;
    float ff;
    D d;
    vec3 c;
    for (float f=0.;f<50.;f+=1.){
      ff = f;
      d=map(mp);
      if (abs(d.d)<.001)break;
      if (d.d<.5)
      c += d.c;
      mp+=d.d*rd;
    }
    c *= .05;

    vec3 b = vec3(1.0);
    float tt = step(mod(time * 10., 5.), 4.);
    float ttt = step(mod(time * 5., 5.), 4.);
    b = mix(vec3(1.0, ttt / 5., 0.0), b, 0.8 + tt * 0.1);
    c = pal(ff/30., vec3(1.0), b, vec3(0.5, 0.3, 0.1), vec3(0.5));

    //c *= mix(c, 1. - c, pow(normalize(length(c)), 0.2));
    c *= mix(c, 1. - c, c.g * 3.);

    gl_FragColor = vec4(c,1);
  }
