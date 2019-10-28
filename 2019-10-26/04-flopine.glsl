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

#define hr vec2(1., sqrt(3.))
#define hdetail 5.
#define vdetail 15.
#define time fGlobalTime
#define PI 3.141592


vec2 hash22 (vec2 x)
{return fract(sin(vec2(dot(x,vec2(23.4,15.1)),dot(x,vec2(12.4,56.4))))*124.5);}

float hash21 (vec2 x)
{return fract(sin(dot(x,vec2(12.4,15.65)))*1245.21);}

vec3 voro (vec2 uv)
{
  uv *= vdetail;
  vec2 uv_id = floor(uv);
  vec2 uu = fract(uv);
  
  vec2 m_point, m_nei,m_diff;
    float m_dist = 10.;
  
  for (int i=-1; i<=1;i++)
  {
    for (int j=-1; j<=1;j++)
    {
      vec2 nei = vec2(float(i),float(j));
      vec2 point = hash22(nei + uv_id);
      point = 0.5+0.5*sin(2.*PI*point+time); 
      vec2 diff = nei + point - uu;
      float dist = length(diff);
      if (dist < m_dist)
      {
        m_point = point;
        m_nei = nei;
        m_dist = dist;
        m_diff = diff;
        }
      
    }
 }
 return vec3(m_point, m_dist);
 }

float hdist (vec2 uv)
{
  uv = abs(uv);
  return max(uv.x, dot(uv, normalize(hr)));
  }
  
  vec4 hgrid (vec2 uv)
{
  uv *= hdetail;
  vec2 ga = mod(uv, hr)-hr*0.5;
  vec2 gb = mod(uv-hr*0.5, hr)-hr*0.5;
  
  vec2 guv = (dot(ga,ga) < dot(gb,gb))? ga : gb;
  
  vec2 id = uv-guv;
  
  guv.y = 0.5-hdist(guv);
  
  return vec4 (guv,id);
  }  
  
  vec3 blue_grid(vec2 uv)
  {
    vec3 v = voro(uv);
    return clamp(vec3(hash22(v.xy).r,hash22(v.xy).y, 1.),0.,1.);
  }
  
  vec3 frame(vec2 uv)
  {
    vec4 hg = hgrid(uv);
    return blue_grid(uv)*step(0.05, hg.y);
    }
  
    mat2 rot(float a)
    {return mat2(cos(a),sin(a),-sin(a),cos(a));}
    
    float od (vec3 p, float d)
    {return dot(p,normalize(sign(p)))-d;}
    
    float g1 = 0.;
    float SDF (vec3 p)
    {
      p.xz *= rot(time);
      p.yz *= rot(time);
      p.x -= sin(time);
      float d = od (p, 1.);
      g1 += 0.1/(0.1+d*d);
      return d;
      }
    

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001,-7.),
  p = ro,
  rd = normalize(vec3(uv,1.)),
  col = vec3(0.01);
  
  float shad = 0.;
  
  for (float i=0.; i<64.; i++)
{
  float d = SDF(p);
  if (d<0.001)
  {
    shad = i/64.;
    break;
    }
    
    p += d*rd;
  }  
  
  col = vec3(1.-shad);
 col *= g1;
  col *= frame(uv);
  
  
  out_color = vec4(col,1.);
}