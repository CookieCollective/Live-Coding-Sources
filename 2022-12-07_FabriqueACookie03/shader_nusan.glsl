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

in vec2 out_texcoord;
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float time=mod(fGlobalTime, 300);

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

mat2 rot(float t) {
  float ca=cos(t);
  float sa=sin(t);
  return mat2(ca,sa,-sa,ca);
}

vec3 rnd3(vec3 r) {
  
  return fract(sin(r*362.574 + r.yzx*483.994 + r.zxy * 675.034)*422.455);
}

float rnd(float t) {
    return fract(sin(t*273.944)*594.033);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1,fract(t)),10));
}

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5, 0, 1);
  return mix(a,b,k) - h*k*(1-k);
}

float map(vec3 p) {
  
  vec3 bp=p;
  
  for(int i=0; i<4; ++i) {
    p.xz *= rot(time*0.2 + i + curve(time, 1.4) + p.y*0.1);
    p.xy *= rot(time*0.3 + i*i + curve(time, 1.7) + sin(p.z*0.1+time));
    p=abs(p)-0.6-sin(curve(time, 0.3 + i*i*0.2))*1.4 - pow(abs(sin(curve(time, 0.5)*0.4)),3)*1.6;
    
  }
  float d = box(p, vec3(0.5,0.1, 2.7));
  float ss=29*curve(time+p.y*0.2, 1)-length(bp)*10*curve(time+p.x*0.1, 1.4);
  ss *= 0.1;
  d = min(d, length(p.xz) - ss);
  d = min(d, length(p.xy) - ss);
  d = min(d, length(p.yz) - ss);
  
  float d2=length(bp)-5 - curve(time+sin(p.z)+sin(p.y+time), 0.3) * 3;
  d=max(d, -d2);
  d = min(d, d2);
  for(int i=0; i<3; ++i) {
    bp.xy *= rot(0.1+time*0.3);
    bp.xz *= rot(0.3+time*0.2);
    bp.xz=abs(bp.xz)-6;
  }
  d=smin(d, length(bp.xz)-1, 16+15*sin(time));
  return d;
}

void cam(inout vec3 p) {
  p.xy *= rot(time*0.3);
  p.xz *= rot(time*0.1);
}

void main(void)
{
  vec2 uv = out_texcoord;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
//uv.x *= 0.66;
  uv.x -= 0.15;
  float anim = floor(time)+pow(fract(time), 30);
  uv = uv * rot(pow(length(uv),3.)+anim);
  float l=fract(time)*500;
  uv=floor(uv*l)/l;
  time = mod(fGlobalTime*0.6, 300);
  time += floor((length(uv)-time)*0.1)*100;
  
  float oo=pow(curve(floor(pow(abs(uv.x),0.8)*6-time)+time*0.4,0.12), 3.0);
  
  time += oo;
  vec3 s=vec3(curve(time, 7)*16-8,0,-50);
  vec3 r=normalize(vec3(uv, 0.2+curve(time, 9.2)));
  
  cam(s);
  cam(r);

  
  float dit = mix(0.9,1.0, rnd3(vec3(uv, fract(time))).x);
  
  vec3 col=vec3(0);
  
  vec3 p=s;
  for(int i=0; i<100; ++i) {
    float d=abs(map(p));
    if(d<0.01) {
      
      //col += map(p-r);
      d=0.1;
    }
    if(d>100) break;
    p+=r*d*dit;
    col += vec3(1,0.4,0.6 + sin(p.x+curve(time, 0.9)*3)) * 0.0005 / (0.5 * d);
    
  }

    float t2=time*0.3-length(uv)*3 + oo*0.3;
 col.xz *= rot(t2);
 col.xy *= rot(t2*0.7);
  col = abs(col);
  
  float fac = curve(time + length((uv-vec2(1,0)*rot(time))), 1.1);
  col = mix(col, vec3(dot(col,vec3(0.333))), fac);
  
  col = smoothstep(0,1,col);
  col = pow(col, vec3(0.4545));
  
  
  out_color = vec4(col, 1);
}