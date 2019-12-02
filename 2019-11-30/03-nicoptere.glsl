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

#define PI acos( -1. )
float n (vec3 p ){
 vec4 a = vec4( 0,57,21,78) + dot( vec3( 1,57,21), floor( p) );
vec4   a1 = a+1.;
  vec3 f = .5 - .5 * cos( fract( p ) * PI ) ;
  a = mix( sin(cos( a)*a), sin(cos( a1) * a1 ), f.x );
  a.xy = mix( a.xz, a.yw, f.y );
  return mix( a.x, a.y, f.z );
  }
   float fbm (vec3 p){
     float r = 0.;
     float a = 1.;
     for (int i =0; i <3; i++)r += (a*=.5) * n(p*=2.);
     return r;
   }
   
float map( vec3 p ){
  
  float t=fGlobalTime, a=t ,ca =cos( a), sa=sin( a);
  
  float st = sin( fGlobalTime * 2.);
  mat2 m = mat2( ca, -st, st, ca );
  p.xz *= m;
  p.yz *= m;
  float pl = dot( p, vec3( 0,1.,0.)) + st ;
  float sp = length( p ) - 1.5 + fbm( p + fGlobalTime ) * ( sin( t * 3. ) ) ;
  return max(  pl, sp);
   }
void main(void)
{
 float ti = fGlobalTime;
  vec2 uv = gl_FragCoord.xy / v2Resolution * 2. - 1.;
  
  uv.x *= v2Resolution.x / v2Resolution.y;
  
  float t, a=ti ,ca =cos( a), sa=sin( a);
  vec3 c = vec3( 0, 0, -3), d = normalize( vec3( uv, 1.) ), p = c + d;
  for( int i =0;  i < 32; i++ ){
    t += map( p );
    p = c + t * d;
  }
  t = log( t - 1. );
  uv = gl_FragCoord.xy / v2Resolution;
  uv *= n( p);
  vec3 col = .5+ .5 * cos( ti + uv.xyx + vec3( 0,2,4 ) );
  out_color = vec4(col * t, 1.);
}