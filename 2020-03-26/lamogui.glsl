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

mat2 rot(float a){
  float c = cos(a);
  float s = sin(a);
  return mat2(c,-s,s,c);
}

float cube( vec3 p, vec3 b ) {
  vec2 uv = p.xy;
  float v = 3.0 * texture(texFFT, fract((uv.x * 0.3))).x;
  b.x += v;
    vec3 q = abs( p) - b;
  return length( max(q, 0.0) ) + min(max(q.x, max(q.y, q.z)), 0.0);
  
}

float qqube( vec3 p ) {
    vec3 q = p;
  q.y +=  sin((p.z+fGlobalTime) *0.3 + p.x * 0.2) * 1.5;
  
  q = mod(q, 5.0) - 2.5;
  q.xy = rot( fGlobalTime) * q.xy;
  q.yz = rot( fGlobalTime) * q.yz;
  
  return cube( q, vec3(1.0));
}

float map(vec3 p) {
  
  float d = qqube(p);
  
  d = max( d,qqube(p*10.0)/10.0 );
return d;
}

vec3 grad(vec3 p ){
  vec2 e = vec2(0.01, 0.);
  return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy), map(p + e.yyx) - map(p - e.yyx)
  ));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 0.0, -2.0 + 1.3 * texture(texFFTIntegrated, 0.01).x);
  vec3 rd = normalize(vec3(uv, 0.8 - length(uv) - texture(texFFT, 0.01).x) );
  
  vec3 p = ro;
  for ( float i = .0; i < 128.0; ++i) {
     float d = map(p);
    if ( abs(d) < 0.001) {
       break;
    }
    p += rd * d;
  }
  
  float dc = exp(-0.2 * distance(ro, p) );
  vec3 n = grad(p);
  
vec3 col = vec3(uv,0.0 ) * vec3(dc ) + vec3(dc)* (n * 0.5 + 0.5) ;
  
  out_color = vec4(col, 1.0);
}