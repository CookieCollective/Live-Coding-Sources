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

vec3 circle(vec2 uv, vec2 pos, float r, float s){

vec3 res = vec3(smoothstep(r,r-s,length(uv+pos)-r));
return res;
}


void main () {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv-=0.5;
    uv.x *= resolution.x / resolution.y;

    vec3 res;


    for (float i=0.; i<100.;i+=1.){
      vec2 pos=vec2(0.5*sin(time+i),0.5*cos(0.5*time+i));
      vec3 col =circle (uv.xy,pos,0.02,0.01);
      col.x*=i;
      res+=   col;

    }

    for (float i=0.; i<100.;i+=1.){
      vec2 pos=vec2(0.5*sin(time+i),0.5*cos(0.5*time+i));

      res-= circle (uv.xy,pos,0.01,0.01);
    }

    for (float i=0.; i<100.;i+=1.){
      vec2 pos=vec2(0.5*sin(time+i+3.14),0.5*cos(0.5*time+i));
      vec3 col =circle (uv.xy,pos,0.02,0.01);
      col.x*=i;
      res+=   col;

    }

    for (float i=0.; i<100.;i+=1.){
      vec2 pos=vec2(0.5*sin(time+i+3.14),0.5*cos(0.5*time+i));

      res-= circle (uv.xy,pos,0.01,0.01);
    }


        for (float i=0.; i<100.;i+=1.){
          vec2 pos=vec2(0.5*sin(time+i+3.14*0.5),0.5*cos(0.5*time+i));
          vec3 col =circle (uv.xy,pos,0.02,0.01);
          col.x*=i;
          res+=   col;

        }

        for (float i=0.; i<100.;i+=1.){
          vec2 pos=vec2(0.5*sin(time+i+3.14*0.5),0.5*cos(0.5*time+i));

          res-= circle (uv.xy,pos,0.01,0.01);
        }







    gl_FragColor=vec4(res,1.);
  }
