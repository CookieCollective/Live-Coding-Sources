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
  float c = 0.5 + sin( v.x * 5.0 ) + cos( sin( time*0.5 + v.y ) * 2.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .2, 1.0 );
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 m;
  m.x = atan(uv.x / uv.y) / (3.14/4);
  m.y = 1 / length(uv) * .2;
  float d = m.y * 4.0;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime  ) * 0.41;
  m.y += fGlobalTime * 0.6;

  vec4 t = plas( m * 3.14, fGlobalTime ) * d;
  t = clamp( t, 0.0, 1.0 );

  vec2 r = uv;
  
  r.y = 4.0 /(r.x*50 + 0.3*r.y);

  float aa = ( 2*mod(r.x,0.2) + 4*mod(r.y+fGlobalTime*0.1*sin(m.x*0.01+fGlobalTime*0.001),0.3) ); 

  t = t* 0.2+1.0*aa;

  out_color = f + t;
}