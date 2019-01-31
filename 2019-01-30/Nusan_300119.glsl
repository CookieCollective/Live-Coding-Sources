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

float sph(vec3 p, float r) {
  return length(p)-r;
}

float box(vec3 p, vec3 s){
  vec3 ap=abs(p)-s;
  return length(max(vec3(0), ap)) + min(0, max(ap.x, max(ap.y,ap.z)));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}


float smin( float a, float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5,0,1);
  return mix(a,b,k) - k*(1-k)*h;
}

float rnd(float t) {
  return fract(sin(t*456.232)*8956.233);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)),rnd(floor(g)+1), pow(smoothstep(0,1,fract(g)), 10));

}

float mat = 0;
float map(vec3 p) {

  vec3 bp=p;
  
  p.y += pow(abs(sin(time))*3,2);
  vec3 rp = p;

  
  float scale = abs(curve(time, 0.8)-0.5)*2;
  scale = smoothstep(0,1,scale);
  scale += 0.3;
  for(int i=0; i<5; ++i) {
    rp = p;
    float t1 = time * 0.7;
    p -= 0.2*scale+i*0.2*scale;
    p.xy *= rot(t1*0.7);
    p -= 0.3*scale+i*0.3*scale;
    p.yz *= rot(t1);
    p=abs(p);
    p -= 0.4*scale+i*0.5*scale;
  }

  float b = box(p, vec3(0.5,0.3,0.7));
  float b2 = box(rp, vec3(0.5,0.5,10.0)*1);
  float b3 = max(b, -b2);

  float ground = 1-bp.y;
  ground=smin(ground, -b3, -5.5);
  
  mat = b3<ground?1:0;

  return min(b3,ground );
}

vec3 norm(vec3 p) {
  vec2 off=vec2(0.01,0);
  return normalize(map(p)-vec3(map(p-off.xyy),map(p-off.yxy),map(p-off.yyx)));
}

void cam(inout vec3 p) {
 float t1=time*0.2;
  p.yz *= rot(0.5);
  p.xz *= rot(t1);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv.x += (curve(time, 0.7)-0.5)*0.3;

  uv.y += (curve(time, 0.9)-0.5)*0.2;

  vec3 s=vec3(0,0,-25);
  vec3 r=normalize(vec3(-uv, 0.5 + curve(time, 1.3)*0.5));

  cam(s);
  cam(r);

  s.y -= 3;

  vec3 col=vec3(0);

  vec3 l = normalize(vec3(-0.7,-1.0,-0.5));

  vec3 p=s;
  float prod=1;
  float none=1;
  float at=0;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) {
      float curmat=mat;
      vec3 n=norm(p);
      vec3 h=normalize(l-r);
      float f=pow(1-max(0, dot(n, -r)),2);
      vec3 diff=mix(vec3(.7,0.3,0.2), vec3(0.3), curmat);
      col += prod*diff*max(0, dot(n, l)) * (0.2 + 1.5*pow(max(0,dot(n,h)),7));
      col += prod*0.2*vec3(0.3,0.3,1.0) * f * 2 * (-n.y*0.5+0.5);

      prod *= 1.0*f+0.5;
      r=reflect(r,n);
      d=0.1;
      none=0;
     // break;
    }
    if(d>100) {
      none=0;
      break;
    }
    p+=r*d;
    at += 0.3*exp(-d*1.9);
  }
  col += none * vec3(0.2,0.2,0.5);
  col += at*0.008*vec3(1,0.7,0.2);

  col *= 5;
  col = 1-exp(-col);
  col = pow(col, vec3(1.2));

  out_color = vec4(col, 1);
}