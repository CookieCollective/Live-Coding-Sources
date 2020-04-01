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
#define iTime fGlobalTime
#define REP(p, r) (mod(p + r * .5, r) - r * .5)

mat2 rotation(float angle)
{
  float cosA = cos(angle); float sinA = sin(angle);
  return mat2(cosA, -sinA, sinA, cosA);
  }

float map(vec3 position)
{
  vec3 cp = position;
  
  
  position.xz *= rotation(iTime * .1 + position.y *.0125);
  
  position.z -=iTime * 2.;
  
  
position = REP(position, 15.);
  
  
  float distan = length(position) - 2.;
  
    position = cp;
  
    distan = max(distan, -length(position.xy) + (1. + sin(position.z - iTime) * .5));
  
  
  return distan;
  }

  vec3 norm(vec3 p)
  {
    vec2 e = vec2(.01,.0);
    float v = map(p);
    return normalize(vec3(v - map(p + e.xyy),
    v - map(p + e.yxy),
    v - map(p + e.yyx)));
    }
  
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 cp = ro;
  vec3 rd = normalize(vec3(uv, 1.));
  
  float cd = 0., st = 0., di = 0.;
  
  for(;st < 1.; st += 1. / 128.)
  {
    cd = map(cp);
    if(abs(cd) < .01 || cd > 10.)
    {
      break;
      }
      
      cp += rd * cd;
      di += cd;
    }
  
    out_color = vec4(0.);
    if(cd < .01)
    {
      vec3 normal = norm(cp);
      
      out_color = vec4(normal, 0.) * di;
      cp *= .01;
      out_color.rg *= rotation(cp.y + iTime);
      out_color.gb *= rotation(cp.z + iTime * .5);
      out_color.br *= rotation(cp.x + iTime * .25);
      out_color *= exp(-di * .0125);
      
      out_color = sqrt(out_color);
      }
}