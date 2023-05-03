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

float time=mod(fGlobalTime, 300);

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

float planet(vec3 p, float size, float dist, float spd) {
  
  p.xz *= rot(time * spd);
  vec3 p2=p;
  p.x-=dist;
  
  float tt=length(vec2(length(p2.xz)-dist, p2.y))+0.1;
  return min(box(p, vec3(size)), tt);
  
}

vec3 rnd(vec3 p) {
 return fract(sin(p*234.545 + p.yzx*644.232 + p.zxy * 512.343)*656.232);  
}

float rnd(float t) {
  return fract(sin(t*343.656)*564.032);
}

vec3 amb=vec3(0);

float camb(float d, vec3 col, float e, float f) {
  amb += col * e * f / (e + abs(d));
  return d;
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1), pow(smoothstep(0,1, fract(t)),10));
}

float map(vec3 p) {

  p.yz *= rot(-0.5 + time*0.2);
  
  vec3 p2=p;
  p2.xz *= rot(time*0.3);
  p2.yz *= rot(time*0.4);
  
  float ss = clamp(texture(texFFTSmoothed, 0.01).x*40 + 0.3, 0, 2);
  float d = camb(box(p2, vec3(ss)), vec3(1,0.7,0.3), 0.9, 0.15);
  
  for(int i=0; i<5; ++i) {
    d = min(d, camb(planet(p, 0.1, rnd(i+0.5)*10+1, rnd(i+0.4)*2+1), abs(sin(rnd(i+0.6)*23+time*0.3+vec3(1,2,3))), 0.1, 0.5));
  }
  d = min(d, planet(p, 0.4, 14, 0.5));
  
  return d;
}



void cam(inout vec3 p) {
  
  p.yz *= rot(sin(time*0.13)*0.4 + time*0.2 + curve(time, 0.8));
  p.xz *= rot(time*0.1+curve(time, 0.9));
}

void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  float hyper=min(curve(time, 0.7),curve(time, 1.8));
  
  uv *= 1 - 0.6*hyper*fract(time);
  
  uv.x += (curve(time, 0.9)-0.5)*0.5;

  vec3 col=vec3(0);
  
  vec3 s=vec3(0,0,-20);
  vec3 r=normalize(vec3(uv, 1));
  
  cam(s);
  cam(r);
  
  vec3 p=s;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) break;
    if(d>100) break;
    p+=r*d;
  }
  
  float fog=1-clamp(length(p-s)/100,0,1);
  
  //col += map(p-r) * fog;
  col += amb;
  
  vec3 stars=vec3(4);
  stars *= smoothstep(0.9,1.0, rnd(floor(r*699)));
  stars *= smoothstep(0.9,1.0, rnd(floor(r*199)));
  col += stars;
  
  col = mix(col, pow(texture(texPreviousFrame, gl_FragCoord.xy / v2Resolution.xy).xyz, vec3(3))*hyper*4, 0.5);
  //col *= 1.4-length(uv);
	out_color = vec4(col, 1);
}