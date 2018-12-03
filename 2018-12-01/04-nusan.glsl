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


float perc=texture(texFFTIntegrated, 0).x;
#define time fGlobalTime

float sph(vec3 p, float r) {
  return length(p) - r;

}


float cyl(vec3 p, float r) {
  return length(p.xy) - r;

}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float smin(float a, float b, float h) {
  float k = clamp((a-b)/h*0.5+0.5,0,1);
  return mix(a,b, k) - k * (1-k) * h;
}

float rnd(float t) {
  return fract(sin(t*234.231)*7423.215);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1, fract(g) ), 10));

}

float map(vec3 p) {

  float d = 10000;
  float j = 10000;

  for(int i=0;i<8; ++i) {

    float t1 = time + i*2.354 + curve(time+85.24, 20.9*i+0.2)*3;
    p.xy *= rot(t1);
    p.yz *= rot(t1*0.7);

    d = smin(d, sph(p, 0.1 * i+.1), 0.2);

    p -= 0.2;
    p = abs(p);

    p.xy *= rot(t1*1.3);
    
    d = smin(d, -cyl(p, 0.05), -0.3);
    j = min(j, cyl(p.yzx, 0.05));
  }

  j = smin(j, sph(p, 1), 0.3);

  return min(j,d);
}

vec3 norm(vec3 p) {
  float base=map(p);
  vec2 off=vec2(0.01,0);
  return normalize( vec3(base-map(p-off.xyy), base-map(p-off.yxy), base-map(p-off.yyx) ));
}

vec3 cam(vec3 p) {
  float t2 = time + curve(time, 0.9)*3;
  p.xy *= rot(t2);
  p.xz *= rot(t2*1.2);
  return p;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv.x += (curve(time+85,0.8)-0.5) * 0.4;
  uv.y += (curve(time+85,0.7)-0.5) * 0.3;

  vec3 ro = vec3(0,0,-3);
  vec3 rd = normalize(vec3(-uv,0.1 + curve(time+52, 1.2)));

  ro=cam(ro);
  rd=cam(rd);

  vec3 p = ro;
  float dd = 0;
  float at = 0;
  for(int i=0;i<100; ++i) {
    float d = map(p);
    if(d<0.001) {
      break;
    }
    if(dd>100) {
      dd = 100;
      break;
    }

    p+=rd*d;
    dd+=d;
    at += exp(-d);
  }


  vec3 n = norm(p);
  vec3 l = normalize(vec3(-1));
  vec3 h = normalize(l-rd);


  vec3 col = vec3(0);
  
  float lum = max(0, dot(n, l));
  float amb = -n.y*0.5+0.5;
  col += vec3(0.8,0.7,0.2) * lum;
  col += vec3(0.2,0.3,1.0) * amb;

  col += vec3(0.8,0.9,1.0) * 0.4 * lum * pow(max(0,dot(n,h)), 10);
  col += vec3(0.1,0.2,1.0) * 4.7 * amb * pow(1-max(0,dot(n,-rd)), 3);

  col *= 4/dd;

  col += pow(at*0.02,0.3) * 0.7;
  
  col += pow(abs(fract(at)-0.5) * (1-step(dd,50)), 5) * 10.2 * curve(time+81,1.4);

  float t3 = time + curve(time+85,1.5);
  col.xy *= rot(t3);
  col.yz *= rot(t3*1.2);
  col.xz *= rot(t3*0.7);
  col = abs(col);

  col *= pow(clamp(1-length(uv),0,1),2);

  out_color = vec4(col, 1);
}