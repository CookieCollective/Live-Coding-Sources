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
uniform sampler2D texRevision;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

// hello laval virtual !
#define time fGlobalTime

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
  
}

float box(vec3 p, vec3 s) {
   p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

float rnd(float a) {
  return fract(sin(a*452.511)*714.712);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1,fract(t)),10));
}

vec3 add=vec3(0);
float map(vec3 p) {
  
  
  float t2=time*.3 + sin(p.y*.3+time);
  p.xz *= rot(t2);
  p.yz *= rot(t2*1.3);
  
  
  vec3 bp=p;
  
  for(int i=0; i<7; ++i) {
    float t=time*.3 + i;
    p.yz *= rot(t*.7 + curve(time, 1.3)*3.2);
    p.xz *= rot(t + curve(time, 1.1)*3.2);
    p.xz=abs(p.xz);
    p.xz-=0.4+curve(time, 3);
  }
  
  float d = box(p, vec3(.3));
  
  add += vec3(0.5,1,.2) * 0.01/(0.1 + abs(d));
  
  float d2 = length(p.xz)-.1;
  add += vec3(0.5,.7,2) * 0.01/(0.1 + abs(d2));
  
  bp.xy=abs(bp.xy)-3.9;
  bp.xy=abs(bp.xy)-0.9;
  float d3 = length(bp.xy)-.2-curve(bp.z+time*3.,.1)*.2;
  add += vec3(1,.4,.2) * 0.07/(0.6 + abs(d3));
  
  d=min(d,d2);
  d=min(d,d3);
  
  d*=.7;
  
  return d;
}

void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv *= 1+curve(time-length(uv),.2)*.3;
  
  vec3 s=vec3(0,0,-17 - curve(time, 1)*70);
  vec3 r=normalize(vec3(uv, 1));
  vec3 p=s;
  
  vec3 col=vec3(0);
  
  for(int i=0; i<100; ++i) {
    float d=abs(map(p));
    if(d<.001) {
      d=.1;
      //break;
    }
    if(d>100.) break;
    p+=r*d;
    
  }
  col += add*.1;
  float fog = 1-clamp(length(p-s)/100,0,1);
  //col += map(p-r)*fog;
  
  float a=time*.2 + uv.y*.5;
  a += smoothstep(0.,.01,abs(uv.x)-.1-.2*curve(time+sin(uv.y*4.+time)*.2, .4));
  col.xz *= rot(a);
  //col.yz *= rot(a*1.3);
  col=abs(col);
  
  col=smoothstep(0,1,col);
  col=pow(col, vec3(.4545));
  
	out_color = vec4(col, 1);
}
