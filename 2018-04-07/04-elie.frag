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

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
  return a+b*cos(6.2831*(c*t+d));
}

void main () {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    //uv -= .5;
    //
    uv.x *= resolution.x / resolution.y;

    float d = length(uv - vec2(0.5, 0.5));


    uv.x += sin(2. * time + uv.x * 10.) * sin(exp(sin(time * 1. + uv.x * 10.)) + uv.y * 10.);

    vec3 c = vec3(uv, 0.);

    c *= 1. - step(d, .05);

    gl_FragColor = vec4(c,1);
  }
