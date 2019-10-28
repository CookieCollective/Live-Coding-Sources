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

float fbm(vec2 p) {
  float d = texture(texNoise,p).r * .5;
  d += texture(texNoise,p*2.).r * .25;
    return d;
  }

 float water(vec3 p) {
   return p.y + texture(texNoise, p.xz*.1+vec2(0.,fGlobalTime*.1)).r*.2+ texture(texNoise, p.xz*.1+vec2(0.,-fGlobalTime*.01)).r*.125 +1.5;
 }
float map(vec3 p) {
  float d = -(length(p.xy)-2.);
  d = max(d, p.y-1.);
  p.z = mod(p.z, 20.)-10.;
  d = min(d, length(p.yz+vec2(-1.5+sin(p.x*.5+5.),0.))-2.);
  d += fbm(p.xz*.1)*3.;
  d = min(d, water(p));
  return d;
}


vec3 raymarch(vec3 ro, vec3 rd) {
  vec3 p = ro;
  for(int i=0; i<32; i++ ) {
    p += rd * map(p)*1.3;
  }
  
  return p;
}

  vec3 ld = normalize(vec3(cos(fGlobalTime),.4,1.));

vec3 sky(vec3 rd) {
  vec3 c = pow( vec3(.3,.5,1.), vec3(rd.y*2.));
  c += vec3(1.,.7,.3) / (1.+length(rd-ld)*200.)*20.;
  return c;
}

vec3 normal(vec3 p) {
  float d = map(p);
  vec2 eps = vec2(0.01, 0.);
  return normalize(vec3(d-map(p-eps.xyy),d-map(p-eps.yxy),d-map(p-eps.yyx)));
}
float shadow(vec3 ro, vec3 ld) {
  vec3 p = ro;
  for(int i=0; i<8; i++) {
    p += map(p) * ld;
  }
  return step(.5, length(p-ro));
}

mat2 rot(float v) {
  float a = cos(v);
  float b = sin(v);
  return mat2(a,b,-b,a);
}

float rand(float v) {
  return fract(sin(v)*42358.);
}

vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n) {
  
  vec3 col = vec3(0);
  float shad = shadow(p, ld);
  col += vec3(1.,.7,.3) * max(dot(n,ld), 0.)*.2 * shad;
  
  col += vec3(.7,.3,1.) *3.* saturate(rand(floor(p.z)+floor(fGlobalTime*3.))*9.-8.);
  col = mix(col, sky(rd), saturate( length(p-ro) * .01));
  
  return col;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,-1.,fGlobalTime*3.);
  vec3 rd = normalize(vec3(uv, 1.));
  
  vec3 rdd = rd;
  rd.xy = rot(fGlobalTime*.1) * rd.xy;
  rd.yz = rot(fGlobalTime*.05) * rd.yz;
  rd = -abs(rd);
  rd.xy = rot(fGlobalTime*.05) * rd.xy;
  rd = -abs(rd);
  rd = mix(rd, rdd, cos(fGlobalTime*.21)*.3+.7);
  vec3 p = raymarch(ro,rd);
  vec3 n = normal(p);
  vec3 col = shade(ro,rd, p, n);

  if(water(p)- map(p) < 0.01) { 
    rd = reflect(rd,n);
    p = raymarch(p+rd*.1,rd);
    col = vec3(.1,.7,1.) * shade(ro,rd,p,n);
  }
  
  col = pow(col, vec3(.4545));
  out_color = vec4(col, 1.);
}