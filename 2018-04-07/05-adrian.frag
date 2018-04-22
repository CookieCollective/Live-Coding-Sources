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
    float width = resolution.x / resolution.y;
    uv.x *= resolution.x / resolution.y;

    //float xCircle = vec2((0.5+0.5*sin(1.*time)) * width * 0.5;
    //
    float timeOffset = 0.;
    float minDist = 10000.;
    for (int i = 0; i < 40; i += 1)
    {
      timeOffset += 0.024;
      vec2 happy = vec2((0.5+0.2*sin(2.7*(time+timeOffset))) * width, (0.5+0.2*cos(0.2+1.9*(time+timeOffset))));
      minDist = min(minDist, length(uv - happy) + (0.016*40. - timeOffset) * .1 );
    }
    float d = length(uv - vec2((0.5+0.3*sin(1.*time)) * width, (0.5+0.3*cos(0.2+1.3*time))));
    //float d1 = length(uv - vec2((0.5+0.2*sin(2.7*time)) * width, (0.5+0.2*cos(0.2+1.9*time))));



    uv.x += sin(2. * time + uv.x * 10.) * sin(exp(sin(time * 1. + uv.x * 10.)) + uv.y * 10.);

    vec3 c = vec3(uv, 0.);

    //c *= 1. - (step(min(minDist, d), .05));
    c *= 1. - (smoothstep(min(minDist, d), .015, 0.075));

    float t = sin(time) * sin(time) + sin(3.14 * time * uv.y) * sin(3.14 * time);
    c = pal(c.x, vec3(0.5), vec3(0.5, 1.0, 0.3), vec3(1.0, 0.5, 0.4 + t * 0.2), vec3(0.5));



    vec4 almost = vec4(c,1) * (uv.x * cos(mod(time, 3.14 * 2.)) - uv.y * sin(mod(-time, 3.14 * 2.)));
    gl_FragColor = almost  ;
  }
