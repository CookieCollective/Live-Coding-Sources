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

#define rep(p,r) (mod(p + r/2.,r) - r/2.)

float sdSphere(vec3 p,float r)
{
  return length(p) -r;
}

mat2 rot(float a)
{
float c  = cos(a); float s = sin(a);
return mat2(c,-s,s,c);
}




float map(vec3 p)
{

  p.yz *= rot(.3);

  float a = atan(p.z,p.x);

  p.y += 1. + sin(fGlobalTime + length(p * .1) );

  float plane = p.y + 1.;


  float d = length(p.xz);




  p.xz *= rot(fGlobalTime *.2+ d * .01);  
  p.y += 1.5 * sin(d * 5 + fGlobalTime) * .1 +1.5;
  p.xz = rep(p.xz, 4.);


  float sp = sdSphere(p,1.);
  

  return min(plane,sp);
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.1,0.);
  return(normalize(vec3(
    map(p - e.xyy) - map(p + e.xyy),
    map(p - e.yxy) - map(p + e.yxy),
    map(p - e.yyx) - map(p + e.yyx)
)));
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;

  float id = 0.;
  for(float st = 0.; st < 1.; st += 1. / 128.)
  {
    float cd = map(cp);
    if(cd < .01)
    {
      id = 1. - st;
      break;
    }
    cp += rd * cd * .5;
  }


  vec3 norm = normal(cp);
  vec3 ld = normalize(cp - vec3(10 * sin(-fGlobalTime),10,10*cos(-fGlobalTime)));
    
  float light = clamp(dot(norm,ld),0.,1.);

  float f = id;
  vec4 base = vec4(.2,.14,.7,1.);

  float l = light * id;
  out_color = vec4(mix(vec4(1.),base,1. - l)) ;
}