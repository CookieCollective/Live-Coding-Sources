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
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 uv2 = uv;
  vec2 uv3 = uv;
  vec2 uv4 = uv;
 

  uv2.x += 0.25;
  uv3.x += 0.5;
  uv4.x += 0.5+fGlobalTime;

  uv2*=0.5;


  uv.y += (sin(uv.x+fGlobalTime/2)/3);
  uv2.y += (cos(uv.x+fGlobalTime/10)/3);
  uv3.y += (sin(uv.x+fGlobalTime/5)/3);


  uv.x -= fGlobalTime*2;
  uv2.x -= fGlobalTime/5;
  uv3.x -= fGlobalTime/10;
  uv4.y -= sin(uv4.x/5)*3;


  vec4 fractal1 = texture( texNoise, uv );

  vec4 wood = texture( texTex3, uv4 );


  uv2.x += fractal1.x;
  uv3.y += fractal1.x;



  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;


  vec2 m2;
  m2.x = atan(uv2.x / uv2.y) / 3.14;
  m2.y = 1 / length(uv2) * .2;



  vec4 fractal2 = texture( texNoise, uv );

  vec4 fractal3 = texture( texNoise, uv2 );

  fractal2.r += sin(fGlobalTime);
  fractal2.g += sin(fGlobalTime+0.5);

  out_color = sin((fractal1*fractal2*fractal3*100)-2)*(wood*3)+0.3;

}




//  vec2 m;
//  m.x = atan(uv.x / uv.y) / 3.14;
//  m.y = 1 / length(uv) * .2;
//  float d = m.y;

// float f = texture( texFFT, d ).r * 100;
 // m.x += sin( fGlobalTime ) * 0.1;
 // m.y += fGlobalTime * 0.25;

 // vec4 t = plas( m * 3.14, fGlobalTime ) / d;
 // t = clamp( t, 0.0, 1.0 );
