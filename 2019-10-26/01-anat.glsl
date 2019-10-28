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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

#define saturate(x) clamp(x, 0., 1.)

float box(vec3 p) {
  vec3 q = abs(p) - .3;
  return length(max(q,0.)) + min( max(q.x, max(q.y,q.z)), 0.);
}
float map(vec3 p) {
  vec3 pp = p;
  p = mod(p,1.)-.5;
  float d = box(p);
  d = max(d, pp.y+1.);
  return d;
}

float rand(float s) {
  return fract(sin(s)*42358.);
}

vec3 albedo(vec3 p) {
  vec2 id = floor(p.xz);
  
  vec3 c = vec3(0.);
  c += vec3(.5,.4,1.) * saturate( cos(length(id)+fGlobalTime*3.) *2.-1.);
  
  if ( mod(fGlobalTime,10.) > 5.)
  c = vec3(.2,.7,1.) * saturate(rand(id.x+rand(id.y)+floor(fGlobalTime*6.))*9.-8.);
  
  c *= rand(id.x + rand(id.y))*5.;
  c *= step(0.3, 1.-abs(p.y+1.));
  return c;
  
  
}


vec3 normal(vec3 p) {
  vec2 eps = vec2(0.01, 0.);
  float d = map(p);
  return normalize(vec3(d-map(p-eps.xyy),d-map(p-eps.yxy),d-map(p-eps.yyx)));
}


mat2 rot(float v) {
  float a = cos(v);
  float b = sin(v);
  return mat2(a,b,-b,a);
}

void camPath(inout vec3 ro, inout vec3 rd) {
    float t = mod(fGlobalTime, 50.);
    if(t < 10. ) {
      ro = vec3(t*6.-50.,10., -20.);
      rd.yz = rot(.6) * rd.yz;
    } else if (t <  20.) {
      ro = vec3(0.,4.+cos(t*.5)*4., t*10.);
      rd.xy = rot(t*.1) * rd.xy;
      rd.xz = rot(t*.01) * rd.xz;
      rd.yz = rot(.3) * rd.yz;
    } else if(t<40.) {
      
      ro = vec3(0.,1., t*1.);
      rd.xy = rot(+t*.1) * rd.xy;
      rd = -abs(rd);
      rd.xz = rot(-t*.1) * rd.xz;
      rd = -abs(rd);
      rd.yz = rot(-t*.1) * rd.yz;
      rd = -abs(rd);
      rd.xz = rot(t*.05) * rd.xz;
      rd = -abs(rd);
    } else {
      
      ro = vec3(1.,-2., -t*1.);
      rd.yz = rot(-.25) * rd.yz;
      rd = -abs(rd);
      rd.xy = rot(t*.5) * rd.xy;
    }
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,2., -15.);
  vec3 rd = normalize(vec3(uv, 2.-length(uv)*.3));
  camPath(ro,rd);
  
  vec3 p = ro;
  for(int i=0; i<256; i++) {
    p += rd * map(p);
  }
  vec3 n = normal(p); 
  vec3 col = vec3(0.);
  col += vec3(1.) * abs(n.y)*.01;
  col += albedo(p)*5.;
  col += albedo(p+n) * 10. *exp( -length(fract(p)*2.-1.)*4.);
  
  col = mix(col, vec3(0.), saturate(length(p-ro)*0.03));
  
  vec2 q = uv *.5+.5;
  col *= pow( q.x*q.y*(1.-q.x)*(1.-q.y)*10., 0.25)*1.5;
  col = pow(col, vec3(.4545));
  out_color = vec4(col,1.);
}