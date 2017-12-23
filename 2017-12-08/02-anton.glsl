#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything


#define REP(p,r) (mod(p + r/2., r) - r/ 2.)

mat2 rot(float a) 
{
  float c = cos(a); float s = sin(a);
   return mat2(c,-s,s,c);
}


float map(vec3 pos)
{

  float t = pos.z;

  float time = fGlobalTime;
  
  time += pow(sin(time * 4.),2.);

  float r = 1.;

  r += sin(pos.z * 0.15 + time) * .5 + .7;

  pos.z -= time * 1. ;

  pos. xy *= rot(t * .01+  sin(t * .1 + fGlobalTime * 2.)); 

  //pos.xy = REP(pos.xy, 100.);


  pos.x = abs(pos.x);



  float cy = distance(pos.xy, vec2(9.));

  

  return  cy - r;
}


vec3 normal(vec3 p)
{
  vec2 e = vec2(.1,0.);

  return normalize(vec3(
    map(p - e.xyy) - map(p + e.xyy),
    map(p - e.yxy) - map(p + e.yxy),
    map(p - e.yyx) - map(p + e.yyx)
));
}


#define STEP 64.

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);


  vec3 ro = vec3(0.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = ro;

  float id = 0.;

  for(float st = 0.; st < 1.; st += (1. / STEP))  
  {
    float cd = map(cp);
    if(cd < .01)
    {
      id = 1. - st;
      break;
    }

    cp += rd * cd;
  }

   vec3 lpos = vec3(0., 0.,15.);
   vec3 ldir = normalize(cp - lpos);

    vec3 norm = normal(cp);
   float li = clamp(dot(norm,ldir),0.,1.);


    float r = mod(fGlobalTime * .5, 2.);
    float f = step(length(uv), r) - step(length(uv), r - .5);

  out_color = mix(vec4(f),vec4(norm,0.),id);
}