#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
#define PI 3.14159
float noise(vec2 p)
{
  return fract(dot(p.x * 54523.1235, p.y * 1328.)) ;
}



mat2 rot(float a )
{
  float ca = sin(a);
  float sa = cos(a);
  return mat2(sa,-ca,ca,sa);
}

float ease(float t)
{
  return floor(t) + sin(fract(t) * PI - PI * .5) * .5 + .5;
}

float map(vec3 p)
{
  float dist = 1000.;

  vec3 cp = p;

float time = fGlobalTime;

  float bpm = 120 / 60.;

  

  p.z += ease(time * bpm) * 20. ;

  
  p.xy *= rot(p.z * .1);

  float st = sin(ease(time * bpm)) * .5 + .5;

p.xy *= rot(time * st + abs(p.y) * .01);
  float cy2 = length(p.xz)  - .75;
  p.xz = mod(p.xz +10, 20) - 10;
 //p.xy *= (-time);
  

  dist = min(dist, length(p) - 1.);


  float cy = length(p.xy) - .5;
 
  dist = min(dist, cy2);

  dist = max(dist,-cy);


  cp.xy *= rot(time * .1);
  p = cp;

  p.x = abs(p.x);
  p.x -=8;
  p.z -= 10.;
  

  float cd  = length(p.xz) - 1.;
dist = min(dist, cd);

  p = cp;
  p.y = abs(p.y);
  p.y -=8;
  p.z -= 10.;
  cd  = length(p.yz) - 1.;
dist = min(dist, cd);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
vec3 rd = normalize(vec3(uv,1.));
 vec3 cp = eye;
  float cd = 0.;
  float st = 0.;
  for(; st < 1.; st += 1. / 64.)
{
    float cd = map(cp);
    if(cd < .01) break;

    cp += rd * .5 * cd;
}
  
  out_color = vec4(1. - st);

  float t = fGlobalTime;

  out_color.xz *= rot(t + cp.z);
  out_color.xy *= rot(t + cp.y);
  out_color.yz *= rot(t + cp.x);

}