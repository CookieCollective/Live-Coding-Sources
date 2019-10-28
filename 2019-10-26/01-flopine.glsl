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

float time = fGlobalTime;
float PI = 3.141592;

float BPM = 70./60.;

float hash21(vec2 x)
{return fract(sin(dot(x,vec2(12.4,13.4)))*12124.4);}

void moda(inout vec2 p, float rep)
{
  float per = 2.*PI/rep;
  float a= atan(p.y,p.x);
  float l = length(p);
  a = mod(a,per)-per*0.5;
 p = vec2(cos(a),sin(a))*l;
  
  }

  mat2 rot(float a)
  {return mat2(cos(a),sin(a),-sin(a),cos(a));}
  
  float stmin (float a, float b, float k, float n)
  {
    float st = k/n;
    float u = b-k;
    return min(min(a,b), 0.5*(u+a+abs(mod(u-a+st,2.*st)-st)));
    }

float cyl (vec2 p, float r)
{return length(p)-r;}

float od (vec3 p, float d)
{
  p.xz *= rot(time);
  return dot(p,normalize(sign(p)))-d;
  }

float tunnel (vec3 p)
{
  p.x += texture(texNoise, p.yz*0.15+vec2(0.,time)).r*0.9;
  p.y += texture(texNoise, p.xz*0.1+vec2(0.,time)).r;
  
  return -cyl(p.xy, 6.);
  }

  float g1 =0.;
  float jelly (vec3 p)
  {
    
    p.x += mix(0.,-0.5+hash21(p.yz),exp(-fract(time*BPM)*8.)*6.);
     p.y += mix(0.,-0.5+hash21(p.xz),exp(-fract(time*BPM)*8.)*6.)*0.5;
    
    p.y += sin(p.z*0.5+time);
    
    moda(p.xy, 3.);
    p.x -= 2.5;
    
    p.xy *=rot(p.z*0.5+time);
    moda(p.xy, 3.);
    p.x -= 1.3;
    
    p.z -= 5.;
    p.yz *= rot(PI/2.);
    
    float o = od(p, .5);
    p.y += 2.;
    p.xz *= rot(sin(p.y+time));
    moda(p.xz, 8.);
    p.x -=.4;
    float d = stmin(o,max(cyl(p.xz, 0.04+p.y*0.1),abs(p.y)-1.5),0.4, 4.);
    g1 += 0.1/(0.1+d*d);
    return d;
    }
  
  float SDF (vec3 p)
  {
    return min(jelly(p),tunnel(p));
    }
  
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
float dither = hash21(uv);
  
vec3 ro = vec3(0.001,0.001,-5.),
  p = ro,
  rd = normalize(vec3(uv,1.)),
  col = vec3(0.);
  
  float shad = 0.;
  
  for (float i=0.; i<64.; i++)
  {
    float d = SDF(p);
    if (d<0.001)
    {
      shad = i/64.;
      break;
      }
      d *= 0.8+dither*0.1;
      p+=d*rd;
    }
    
    float t= length(ro-p);
  col = vec3(shad);
   col += g1*vec3(0.5,0.4,0.)*0.3;
  col = mix(col, vec3(0.,0.4,0.6)*0.3, 1.-exp(-0.005*t*t));
  out_color = vec4(sqrt(col),1.);
}