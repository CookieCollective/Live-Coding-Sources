#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI acos(-1.)
#define TAU (2.*PI)
#define rot(a) mat2(cos(a),sin(a), -sin(a),cos(a))

float box2d(vec2 p, float c)
{
  vec2 q = abs(p)-c;
  return min(0., max(q.x, q.y))+length(max(q, 0.));
  }

float tore (vec3 p, vec2 d, float speed)
{
  vec2 q = vec2(length(p.xy)-d.x, p.z);
  float a = atan(p.x,p.y);
  //q *= rot(cos(a));
  
  q.y = abs(abs(q.y)-.2)-0.1;
  
  return box2d(q, d.y);
}

float SDF (vec3 p)
{
  p.yz *= rot(-atan(1./sqrt(2.)));
  p.xz *=rot(PI/4.0);
  
  vec3 pp = p;
  
  vec2 per = vec2(2.25);
  vec2 id = floor(p.xz/per);
  float py = p.y+sin(length(id)-fGlobalTime*2.)*.2;
  p.xz = mod(p.xz, per)-per*.5;
  float d  = tore(vec3(p.x, p.z, py),vec2(1., .04), length(id+.1)*.5); 
  
  p = pp;
  vec2 nid = floor((p.xz-per*.5)/per);
  p.y += sin(length(nid)-fGlobalTime*1.5)*.5;
  
  p.xz = mod(p.xz-per*.5, per)-per*.5;
  d = min(d, length(p)-.5);
  
  return d;
  }
  
  vec3 gn (vec3 p)
  {
    vec2 eps = vec2(0.001, 0.);
    return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
    }
  
  
    float AO (vec3 p, vec3 n, float e)
    {return clamp(SDF(p+e*n)/e,0., 1.);}
    
    
    float spec (vec3 rd, vec3 l, vec3 n)
    {return pow( max(dot(n,normalize(l-rd)),0.), 25. );}
    
    
void main(void)
{
	vec2 uv = (2.*gl_FragCoord.xy - v2Resolution.xy) / v2Resolution.y;
	
  vec3 ro = vec3(uv*5., -20.), rd=normalize(vec3(0.,0., 1.)), p=ro,
  col = vec3(0.), l=vec3(0.8, 1., -1.);
  
  bool hit=false; float shad;
  for(float i=0.; i<64.; i++)
  {
    float d = SDF(p);
    if (d<0.01)
    {
      hit = true; shad=i/64.; break;
      }
      p += d*rd*.6;
    }
  if (hit)
  {
      vec3 n = gn(p);
    float ao = AO(p,n,0.05)+AO(p,n,0.15)+AO(p,n,0.25);
    float sp = spec(rd, l, n);
    col = vec3(1-shad*1.5);
    col *= ao/3.;
    col += sp;
    
    }
  out_color = vec4(col, 1.);
}