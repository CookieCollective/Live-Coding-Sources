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

float mat = 0.;

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  
  return mat2(ca,-sa,sa,ca);
  }


float map(vec3 p)
{
  vec3 cp = p;
  float r = 15.;
  
  p.xy *= rot(p.z * .02 + fGlobalTime * .1);
  
    for(float i = 1.; i < 5. ; ++i)
    {
      p -= fGlobalTime * .01;
      p.xy *= rot(fGlobalTime * .025);
      p * 1.1;
      p = abs(p);
      
      }
  p = mod(p + r/ 2., r) - r/2.;
  
  p.x = abs(p.x) ;
  p.y -= p.x* abs(sin(fGlobalTime * 3.)+ .7);
  float dist = length(p) - 1.;
  
  
  p = cp;
  
  p.xy *= rot(p.z * .02);
  
  float tunnel =max(p.x,p.y) - 6.;
  if(tunnel < .01)
  {
    mat = 1.;
    }
    
  dist = min(-tunnel, dist);
  
    
    p = cp;
    
    for(float i = 1.; i < 5. ; ++i)
    {
      p.xz -= fGlobalTime * .01;
      p.xz *= rot(fGlobalTime * .025);
      p.xz * 1.1;
      p.xz = abs(p.xz);
      
      }
    p.y += (sin(p.z) + cos(p.x));
    float s = p.y + 5.;
    
    dist = min(dist, s);
  return dist;
  }

    vec3 normal(vec3 p)
    {
      vec2 e = vec2(.01,.0);
      float d = map(p);
      return normalize(vec3(d - map(p + e.xyy),d - map(p + e.yxy),d - map(p + e.yyx)));
    }
  
float ray(inout vec3 cp, vec3 rd, out float st)
{
    float cd = 0.;
    st = 0.;
    for(;st < 1.; st += 1./128.)
    {
       cd = map(cp);
      if(cd < .01)
        break;
      cp += rd * cd * .5;
    }
  
  return cd;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = ro;
  float st;
  float cd = ray(cp, rd, st);
  
  if(cd < .01)
  {
    vec3 ld = vec3(-1.,-1.,1.);
    if(mat == 1.)
    {
//      ld = - normalize(vec3(0.) - cp);
      }
    
      float sound = texture(texFFTSmoothed, .025).r;
      
    vec3 norm = normal(cp);
    float li = abs(dot(ld, norm));
      cp.xy *= rot(cp.z * .1 + fGlobalTime + sound);
    out_color = vec4(cp, 0.) * li;
  }
  
  
  }