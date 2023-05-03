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

#define hr vec2(1.,sqrt(3.))

#define cyl(p,r,h) max(length(p.xy)-r, abs(p.z)-h)
#define PI acos(-1.)
#define TAU (2.*PI)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define time fGlobalTime

#define hash21(x) fract(sin(dot(x,vec2(234.1, 381.5)))*1364.45)

#define pal(t,c) (vec3(.5)+vec3(.5)*cos(TAU*(c*t+vec3(0.1, .36, .64))))

#define hex(p) max(abs(p.x),dot(abs(p),normalize(hr))) 

#define swi floor(sin(time*PI)+1.)


vec4 hexgrid (vec2 uv)
{
  vec2 ga = mod(uv,hr)-hr*.5, gb=mod(uv-hr*.5,hr)-hr*.5, guv=(length(ga)<length(gb))?ga:gb,
  gid = uv-guv;
  return vec4(guv,gid);
  }

void moda(inout vec2 p, float rep)
{
  float per = TAU/rep;
  float a = atan(p.y,p.x);
  a = mod(a,per)-per*.5;
  p = vec2(cos(a),sin(a))*length(p);
}

void mo(inout vec2 p, vec2 d)
{
  p = abs(p)-d;
  if(p.y>p.x)p=p.yx;
  }

float SDF (vec3 p)
{
  p.z += time*2.;
  p.x += sin(p.z*2.)*.5;
  p.y += cos(p.z*1.5)*.25;

  p.xy *= rot(p.z*.25);
  float r = mix(2., 8., sin(time)*.5+.5);  
  moda(p.xy, r);
    p.x -= 2.;
    return cyl(p, 1., 1e10);
}

void main(void)
{
	vec2 uv = (2.*gl_FragCoord.xy - v2Resolution.xy)/v2Resolution.y;
  vec2 uu = gl_FragCoord.xy/v2Resolution.xy; 
  
  uv *= rot(time);
  
  if(swi>.5) mo(uv,vec2(.1));
  
  vec2 up = uv;
  up += vec2(cos(time),sin(time))*.5;
  moda(up,5.);
  vec4 hg = hexgrid(up*3.-time);
  uv +=  smoothstep(0.35,0.5,hex(hg.xy))*.1;
  
  float dither = hash21(uv);
  vec3 ro = vec3(0.001, 0.001, -3.), rd=normalize(vec3(uv,1.)),p=ro,
  col = vec3(0.);
  
  
  float shad = 0.;
  for(float i=.0; i<32.; i++)
  {
    float d = SDF(p);
    if (d<0.01)
    {
      shad = i/64.;
      //break;
      }
      d *= .9+dither*.01;
      d = max(0.025, abs(d)-0.025);
      p += d*rd;
    }
  
    float t = length(ro-p);
    
    col = mix(pal(p.z, vec3(.1+sin(time)*.5)),vec3(1.),shad*.05);
  col = mix(col, vec3(0.),1.-exp(-0.01*t*t));
  col = mix(col, pow(col,vec3(0.8,2.,.1)), length(uv)-.1);
    col = mix(col, 1.-col, step(.48,hex(hg.xy)));
  out_color = vec4(sqrt(col), 1.);
   out_color += texture(texPreviousFrame,uu )*.25;
}