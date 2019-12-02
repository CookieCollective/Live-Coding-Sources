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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

mat2 rot(float a)
{
  float ca =cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
  }

  #define PI 3.14159
  
  
  float m = 0;
  
float map(vec3 p)
{
  float ft = fract(fGlobalTime);
  float time = floor(fGlobalTime) + ft * ft;
  
  p *= 1. + sin(p.z * .1 + fGlobalTime) * .5;
  
  vec3 cp = p;
  
  p.z -= time * .01;
  p.xy *= rot(p.z * (.1 + pow(sin(time * .1),2.) * .05 ));
  
  
  p.z -= time * .01;
  p.y = -abs(p.y);
  
  float amp = 1.;
  
  for(float i = 1.; i < 5.; ++i)
  {
      p.y += sin(p.x) * sin(p.z) * amp ;
    amp *= .25;
      p.xz *= rot(.4545 + time * .1 + i * 5.);
    }
  float dist  = p.y + 2.;
    
    if(dist < .01) m = 1;
p = cp;
    
    p.xy *= rot(p.z * .2);
    
    p.x = abs(p.x);
    p.x -= 2. + sin(p.z +time);
    float cyl = length(p.xy) - .25;
    if(cyl < .01) m = 2;
    dist = min(dist, cyl);
    
  return dist;
  }

void ray(inout vec3 p, vec3 rd, out float st)
{
  for(st = 0.; st < 1.; st  += 1. / 128.)
  {
    float cd  = map(p);
    if(cd < .01)
    {break;
      }
      p += rd * cd * .5;
    }
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  for(float i = 1.; i < 5.; ++i)
  {
    uv.y = abs(uv.y);
    uv -= .25;
    uv *= rot(1. + fGlobalTime * .1);
  }  
  float st;
  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;
  
  ray(cp, rd, st);
  
  
  if(st < 1.)
  {
    vec3 c = vec3(1.);
    if( m == 1) c = vec3(.9,.3,.4);
    if( m == 2) c = vec3(.04,.56,.8);
    out_color = vec4(c, 0.) * st;
    
    out_color = pow(out_color, vec4(.4545));
  
    out_color.rg *= rot(cp.z);
    out_color.gb *= rot(cp.z * .25);
    out_color.br *= rot(cp.z * .5);
    out_color = abs(out_color);
    
    }
  }