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
#define PI 3.14159
#define TAU (2.*PI)

float rng (vec2 seed) { return fract(sin(dot(seed*.1,vec2(123,165)))*121513.); }

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float amod(inout vec2 p, float count) {
  float an = TAU/count;
  float a = atan(p.y,p.x)+an/2.;
float c = floor(a/an);
  a = mod(a,an)-an/2.;
  p = vec2(cos(a),sin(a))*length(p);
  return c;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  //uv.xy *= rot(time+length(uv));
vec2 uvv = uv;
  float index = amod(uv, 8.);
  
  uv.y = mix(uv.y, -uv.y, mod(index, 2.));
  

  float star = 0.;
  float circle = 0.;
  for (int i = 0; i < 100; ++i) {
  
  vec4 fft = texture(texFFT, i/100.); 
  vec2 p = uv;
  float a = rng(vec2(i))*TAU;
a += time;
float radius = .1;
float r = mod(time*.1+i*.1, 1.);
  radius *= clamp(r,0.,1.);
  //radius *= smoothstep(0., .2, length(p));
  p.xy += vec2(cos(a),sin(a))*r;
  p.x *= .8;
  p.y += -sin(abs(p.x*1.5))*.5;
  //p = normalize(p)*mod(length(p)- time*.1 + i * .2,1.);
  float c = 1.-smoothstep(radius*.99,radius, length(p));
  c *= 1.-clamp(length(p)*8.,0.,1.);
    circle += c;
  a = rng(vec2(i+3.))*TAU;
   r = i*.1;
  p = uvv;
  //p.xy *= rot(time+i);
r = mod(time*.3+r, 1.);
  float thin = .01 * r;
p.xy += vec2(cos(a),sin(a)) * r;
      float x = thin/clamp(length(p.x),0.,1.);
      float y = thin/clamp(length(p.y),0.,1.);
star += x*y*(.01/clamp(length(p),0.,1.));
  //circle += .01/length(p);
  
  }
  vec4 color = vec4(circle,0,0,1);
color += star;
  out_color = color;
}