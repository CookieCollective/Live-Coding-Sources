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

#define time fGlobalTime

float sph(vec3 p, float r){
  return length(p)-r;
}


float cyl(vec2 p, float r){
  return length(p)-r;
}

vec3 rep(vec3 p, float s) {
  return (fract(p/s-0.5)-0.5)*s;
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float smin(float a,float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5,0,1); 
  return mix(a,b, k) - k * (1-k)*h;
}

float rnd(float t){
  return fract(sin(t*423.23)*4568.232);
}

float curve(float t, float d) {
  float g = t/d;
  return mix( rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1, fract(g)), 10));
}

float map(vec3 p) {

  vec3 rp = rep(p, 0.1);
  vec3 rp2 = rep(p, 0.12);

  float f = texture(texNoise, p.xz * 0.1).x;

  float v = clamp(length(p.xz)*0.5, 0, 1) * 1.5;

  float m = -p.y + 0.1 + f*2 + v;

  float o = -p.y + 2.1;

  float c = cyl(rp.xz, 0.02);
  float c2 = cyl(rp2.xz, 0.02);

    float m2 = -p.y + 0.1 + f*2 + v;

  c = smin(m+.2 - f*2, c, -0.2);
    c = smin(m+.2 - f*2+0.1, c2, -0.2);

  return min(c,min(m, o));
}



vec3 norm(vec3 p) {
  float base = map(p);
  vec2 off = vec2(0.01,0);
  return normalize( vec3( base-map(p-off.xyy), base-map(p-off.yxy), base-map(p-off.yyx) ));
}

vec3 cam(vec3 p) {
  float t = time;
  p.xz *= rot(t);
  p.yz *= rot(sin(t + curve(time+5,1.2)*0.5) * 0.1);
  return p;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv.x += (curve(time+5, 0.7)-0.5) * 0.4;
  uv.y += (curve(time+5, 0.8)-0.5) * 0.3;

  vec3 ro = vec3(0,1,-5);
  vec3 rd = normalize(vec3(-uv, 0.1 + curve(time, 0.2) * 2));

  ro = cam(ro); 
  rd = cam(rd);
  

  vec3 p = ro;
  float dd = 0;
  for(int i=0; i<100; ++i) {
    float d = map(p);
    if(d<0.001) {
      break;
    }
    if(dd>100) {
      dd=100;
      break;
    }
    p+=rd*d*0.5;
    dd+=d*0.5;
  }

  vec3 n = norm(p);
  vec3 l = normalize(vec3(-1));
  vec3 h = normalize(l-rd);

  float lum = max(0, dot(n,l));
  float amb = -n.y*0.5+0.5;

  vec3 col = vec3(0);

  col += vec3(1,0.9,0.5) * lum * 0.5;
  col += vec3(0.2,0.2,1.0) * amb * 0.2;
  col += vec3(0.9,0.9,1.0) * lum * pow(max(0, dot(n,h)),30);;

  col *= 5/dd;

  col += vec3(1,0.5,0.2) * 0.1 * exp(dd*0.2);

  float t2 = time + curve(time+85, 0.8) +  + curve(time+45, 1.3);


  col.xy *= rot(t2);
  col.zy *= rot(t2*0.7);
  col.xz *= rot(t2*1.2);

  col = abs(col);

  col *= min(1,pow(1-length(uv*0.9),2) * 10);

  out_color = vec4(col, 1);
}