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

float time=mod(fGlobalTime, 120);

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
  }
  
float tick(float t, float d) {
  float g=t/d;
  float c=fract(g);
  c=smoothstep(0,1,c);
  c=pow(c, 10);
  return (c + floor(g))*d;
}
  
vec3 fractal(vec3 p, float t1) {
  
  for(int i=0; i<3; ++i) {
    float t=tick(t1, 0.3 + i*0.2)+i;
    p.xz *= rot(t);
    p.zy *= rot(t*1.3);
    
    p=abs(p);
    p-=1.2 + sin(time*0.7)*0.6;
    p.x += sin(time*0.3)*1;
  }
  return p;
}


float map(vec3 p) {
  
  vec3 bp=p;
  
  
  float t=tick(time,1.3)*0.3;
  p.xy *= rot(t);
  p.zy *= rot(t*1.3);
  
  
  
  vec3 p2 = fractal(p, time*0.3);
  
  vec3 p3 = fractal(p+vec3(1,0,0.4), time*0.2);
  
  
  float d=box(p2, vec3(0.4));
  
  float d2=box(p3, vec3(2,0.3,0.6));
  
  d=max(abs(d),abs(d2))-0.8;
  
  d=max(d, -bp.z-10);
  d=max(d, bp.z-5);
  
  return d;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv *=rot(time*0.2 + tick(time,1.3));

  vec3 s=vec3(0,0,-16);
  float fov=0.9+sin(tick(time+0.2,0.5) + time * 0.2)*0.3;
  vec3 r=normalize(vec3(-uv, fov));
  
  vec3 p=s;
  float at=0;
  bool inside=false;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) {
      inside=true;
        break;
    }
    if(d>100) {
        break;
    }
    p+=r*d;
    at += 1.2/(1.2+abs(d));
  }
  
  if(inside) {
    vec2 off=vec2(0.01,0);
    vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
    r=refract(r,n,0.5);
    
  }
  
  float dd=length(p-s);
  vec2 uv2 = p.xy / (dd*r.z);

  vec3 col=vec3(0);
  vec2 grid=step(fract(uv2*6),vec2(0.5));
  vec2 grid2 = abs(fract(uv2*12)-0.5)*2;
  
  float val=min(grid.x,grid.y);
  val += 1-max(grid.x,grid.y);
  
  float anim=mod(time*0.5 - length(uv)*0.3, 4);
  float pop=floor(anim);
  
  if(pop==1) {
    val = step(0.9,max(grid2.x, grid2.y));
  }
  
  if(pop==3) {
    val = step(0.2,sin(max(grid2.x, grid2.y)*13));
  }
  
  if(inside) {
    val =1-val;
  }
  
  col += val;
  col *= at * 0.06;
  
  col*=1.3;

  col *= 1.2-length(uv);
  
  float t3 = pop*1.3 + time*0.2;
  col.xy *= rot(t3);
  col.yz *= rot(t3*0.7);
  col=abs(col);
  
  col += max(vec3(0), col.yzx-1);
  col += max(vec3(0), col.zxy-1);
  
  col = pow(col, vec3(0.4545));
  

  
  out_color = vec4(col, 1);
}