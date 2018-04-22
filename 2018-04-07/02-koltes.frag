/*
{"IMPORTED": {
    "guinness": {
      "PATH": "./guinness.png",
    },
  },
  "pixelRatio": 1.5,
  "audio": true,
  "camera": true,
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
  float m;
};

D map(vec3 p){
  p.xy *= rot(time * .3 + p.z * .01);
  p.yz *= rot(time * .5);
  float rp=4. + sin(time) * 2.;
  vec3 idx=floor((p+rp)/rp/2.);
  p = mod(p + rp, 2.*rp) - rp;

  p.xy *= rot(time * sin(idx.x));
  p.yz *= rot(time * sin(idx.y));

  D d;
  float r = mix(.8,1.,smoothstep(-1.,1.,p.y)-.5);
  d.d= length(p.xz) - r;
  d.d = max(d.d, abs(p.y)-1.5);
  float a=(atan(p.z,p.x)/6.2831+.5)*2.;
  vec4 logo = texture2D(guinness, vec2(a, p.y * 1.));
  logo.rgb=mix(logo.rgb, 1.-logo.rgb, 1.-length(logo.rgb));
  vec3 blk=mix(vec3(.1), logo.rgb, logo.a);
  d.c=mix(blk,vec3(1),step(1.2,p.y));

  d.m = mix(.01, .05, step(0., length(p.xz) - r - .2));
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
      mp+=max(d.d, d.m)*rd;
    }
    c *= .05;
    //c *= 1. - ff/50.;
    vec3 green = pal(time*.2 - length(uv), vec3(.2, .8, .3), vec3(.2), vec3(1., 3., 2.), vec3(0.));
    //c = mix(green, c, 1.-smoothstep(45., 49., ff));
    gl_FragColor = vec4(c,1);
  }
