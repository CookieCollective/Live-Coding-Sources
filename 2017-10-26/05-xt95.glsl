#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNogozon;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float o(vec3 p)
{
  return cos(p.x) + cos(p.y*.5) + cos(p.z) + cos(p.y*20. + fGlobalTime)*.1 + texture(texNoise, p.xy*.1).r*2. ;
}
float water( vec3 p)
{

  float d = p.y + texture(texNoise, p.xz*.1+vec2(fGlobalTime*.01)).r*.1+ texture(texNoise, p.xz*.1-vec2(fGlobalTime*.05)).r*.1;
  d = min(d, mix(length(p-vec3(0.,1.,fGlobalTime+5.)) - 1., length(p.xy-vec2(sin(p.z),1.+cos(p.z))) - .5, cos(fGlobalTime)*.5+.5));
  return d;
}
float map( vec3 p)
{
  float d = min(o(p), water(p));
  return d;
}

vec3 rm( vec3 ro ,vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<64; i++)
  {
    float d = map(p);
  p += rd *d;
  }
return p;
}

vec3 normal( vec3 p)
{
  vec2 eps = vec2(0.01, 0.);
  vec3 n;
  n.x = map(p) - map(p+eps.xyy);
  n.y = map(p) - map(p+eps.yxy);
  n.z = map(p) - map(p+eps.yyx);
  return normalize(n);
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
vec3 shade( vec3 ro, vec3 rd, vec3 n, vec3 p)
{
  vec3 col = vec3(0.);
  col += vec3(1.) * max(0., dot(n, normalize(vec3(1.,1.,1.))))*.5;
  vec3 fog = mix(vec3(cos(fGlobalTime)*.5+.5, .7, .5), vec3(0.,.7,1.5), rd.x) * (length(p-ro)*.05 );;

  col += fog;
  return col;
}

mat2 rot( float v)
{
  float a = cos(v);
  float b = sin(v);
  return mat2( a,-b,b,a);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3( 0., 1., fGlobalTime);
  vec3 rd = normalize( vec3(uv, 1.) );
  rd.xy = rot(fGlobalTime*.1) * rd.xy;
  vec3 p = rm(ro ,rd);
vec3 n = normal(p);

  vec3 col = shade(ro,rd,n,p);
  for(int i=0; i<3; i++)
  if(water(p)<.1)
  {
    rd = reflect(  rd, n);
    p += rd*.1;
  ro = p;
    p = rm(ro,rd);
    n = normal(p);
    col = vec3(0.5,.7,1.) * shade(ro,rd,n,p);
  }
  
  out_color = vec4(col, 1.);
}