#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D karl;
uniform sampler2D lionel;
uniform sampler2D texChecker;
uniform sampler2D texNoise;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float time = fGlobalTime;
float PI =  3.141592;
float TAU = 2.*PI;
float ITER = 100.;

void moda (inout vec2 p, float rep)
{
  float per = TAU/rep;
  float a = atan(p.y,p.x);
  float l = length(p);
  a = mod(a,per)-per*0.5;
  p = vec2(cos(a),sin(a))*l;  
}

void mo (inout vec2 p, vec2 d)
{
  p = abs(p)-d;
  if (p.y>p.x) p = p.yx;
}

float stmin (float a, float b, float k, float n)
{
  float st = k/n;
  float u = b-k;
  return min(min(a,b), 0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float heart (vec2 uv)
{
  uv.x = abs(uv.x)-0.02;
  uv *= rot(-PI/6.);
  return step(length(uv*vec2(1.,0.5)),0.05);
}

vec3 texturing (vec2 uv, sampler2D text, float detail)
{
  uv *= detail;
  float ux = (sin(time*2.*PI)>0.)? uv.x : 1.-uv.x;
  float uy = 1.-uv.y;
  vec2 uu = vec2(ux,uy);
  
  uv = fract(uv)-.5;
  uv *= rot(time);
  moda(uv, 5.);
  uv.x -= 0.15+sin(time)*0.1+0.1;
  float h = heart(uv);
  
  return clamp(texture(text, uu).rgb + vec3(0.8,0.,0.2)*h,0.,1.);
}

float box (vec3 p, vec3 c)
{
  vec3 q = abs(p)-c;
  return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r,abs(p.z)-h);}

float od (vec3 p , float d)
{return dot(p,normalize(sign(p)))-d;}

float width = 2.;
float cadre (vec3 p)
{
  float b1 = box(p,vec3(width,width,0.1));
  b1 = max(b1, -box(p,vec3(width*.8,width*.8,10.)));
  return b1-0.05;
}

float frame (vec3 p)
{return box(p,vec3(width,width,0.01));}


float room (vec3 p)
{
  return -box(p,vec3(8.,3.,1e10));
}

float columns (vec3 p)
{
  float per = 8.;
  p.z = mod(p.z,per)-per*0.5;
  p.x = abs(p.x)-7.5;
  return cyl(p.xzy, 0.5, 8.);
}

float g1 = 0.;
vec3 lionel_p;
float lionel_od(vec3 p)
{
  p.z -= time;
  p.z -=3.;
p.xz *= rot(time);
p.yz *= rot(time);  
  lionel_p = p;
  float d = od(p, 2.);
  g1 += 0.1/(0.1+d*d);
  return d;
}

int mat_id;
vec3 sdf_p;
// sign distance function
float SDF (vec3 p)
{
  p.z += time;
  //p.xy *=rot(p.z*0.02);
  float r = room(p);
  float colu = columns(p);
  float ld = lionel_od(p);
 float per = 8.;
  p.z = mod(p.z-per*0.5,per)-per*0.5;
  p.x = abs(p.x)-7.5;  
  p.xz *= rot(PI/2.);
 
  float fr = frame(p);
  float ca = cadre(p);
  float d = min(ld,min(stmin(r,colu,0.5,3.),min(ca,fr)));
  
  if (d == fr) mat_id = 1;
  if (d == ca || d == r || d == colu  || d == ld) mat_id = 2;
  
  sdf_p = p;
  
  return d;
}

vec3 getcam (vec3 ro, vec3 tar, vec2 uv)
{
  vec3 f = normalize(tar-ro);
  vec3 l = normalize(cross(vec3(0.,1.,0.),f));
  vec3 u = normalize(cross(f,l));
  return normalize(f+l*uv.x+u*uv.y);
}

vec3 getnorm (vec3 p)
{
  vec2 eps = vec2(0.1,0.);
  return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float lite (vec3 n, vec3 l)
{return dot(n,l)*0.5+0.5;}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001,-8.),
  p = ro,
  tar = vec3(0.),
  rd = getcam(ro,tar,uv),
  l = normalize(vec3(0.,2.,-3.)),
  col = vec3(0.);
  
  float shad = 0.;
  bool hit = false;
  
  for (float i = 0.; i<ITER; i++)
  {
    float d = SDF(p);
    if (d<0.001)
    {
      hit = true;
      shad = i/ITER;
      break;
    }
    
    p += d*rd;
  }
  float t =length(ro-p);
  if (hit)
  {
    if (mat_id == 1) col = texturing(sdf_p.xy-vec2(1.6), karl, 0.3);
    if (mat_id == 2) col = mix(vec3(0.5,0.01,0.), vec3(0.8,0.8,0.6),lite(getnorm(p),l));
    col *= vec3(1.-shad); 
  }

  col = mix(col,vec3(0.5,0.1,0.1), 1.-exp(-0.001*t*t));
  
  col += g1* texturing(lionel_p.xy, lionel, 0.15);
  
  out_color = vec4(col,1.);
}