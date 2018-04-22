/*
{"IMPORTED": {
    "guinness": {
      "PATH": "./guinness.png",
    },
  },
  "pixelRatio": 2,
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

#define rand(x) fract(sin(x)*1e4)

float map(vec3 p){
  p.z -= time * 5.;
  p.xy *= rot(p.z * .05);
  vec3 idx=floor((p)/6.);
  p = mod(p, 6.) - 3.;
  p.xz *= rot(time * .5 + sin(idx.x));
  p.xy *= rot(time * .8 + sin(idx.y));
  p.yz *= rot(time * .8 + sin(idx.z));
  //p.xy += -2. +  4.*rand(idx.xy + vec2(0., 3.));
  float a=atan(p.y,p.x)/6.2831;
  a+=1./8.;
  a=floor(a*4.)/4.;
  p.xy*=rot(a*6.2831);
  p.x-=abs(p.y)*.8+.9;
  p.y*=1.2;
  p.z=sqrt(abs(p.z)*3.);
  return length(p)-1.;
}


void main () {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv-=0.5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro=vec3(0,0,-5),rd=normalize(vec3(uv,1.-length(uv)*.5)),mp=ro+rd*3.;
    float ff;
    for (float f=0.;f<30.;++f){
      ff=f;
      float d=map(mp);
      if (d<0.01)break;
      mp+=rd*d;
    }
    vec3 c=mix(vec3(0,1,0) *(1. -ff/30.), vec3(0), smoothstep(25.,30.,ff));
    gl_FragColor=vec4(c,1.);
  }
