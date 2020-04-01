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


#define REP(p,r) (mod(p + r/2.,r) - r/2.)

#define iTime (fGlobalTime)

mat2 rot(float a)
{
  float ca = cos(a); float sa  = sin(a);
  return mat2(ca,-sa,sa,ca);
  }

float map(vec3 p)
{
  
  vec3 cp = p;
  
  
  float dist = p.y + 1.;
  
  p.xy *= rot(p.z * .01 - iTime * .001);
  dist  = cos(p.x) + cos(p.y) + cos(p.z);
  p = cp;
  
  
  //p += iTime;
 // p = REP(p , 17.);
  
  float cu = max(max(p.x,p.y),p.z);
  
  dist = min(dist, cu);
  
  p = cp;
  
  dist = max(dist, -length(p) + 10.);
  
  return dist;
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  vec3 cp = vec3(0.,5.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));

  float st = 0.; float cd  = 0.; float di = 0.;
  for(; st < 1.;  st += 1./256.)
  {
    cd = map(cp);
    if(abs(cd) < .01 || cd > 30.)
    {
      break;
      }
      
      
      cd = min(cd, 1.);
      cp.xz *= rot(sin(st * .001 + iTime * .0025));
      cp += rd * cd;
      cp += normalize(vec3(0.,0.,-5.) - cp) * pow(length(vec3(0.,0.,-5.) - cp), 1. + sin(iTime) * .5) * .001;
      di += cd;
    }
  

 float f = 1. - st;
  out_color = (vec4(sin(di * .02), cos(di * .003 + .2), sin(di+ iTime) , 1.) * .5 + .5) * exp(-di * .05);
    
    out_color = pow(out_color,vec4(.4545));
}