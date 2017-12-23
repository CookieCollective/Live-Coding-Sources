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


float bass()
{
  float b = 0;
  for (int i=0; i<8; ++i)
  {
    b = max(b,texelFetch(texFFTIntegrated,i,0).x);
  }
  return b;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 origuv = uv; 


  float time = bass()+(fGlobalTime/10);

  uv.y += (sin(uv.x*5+time))/10-(uv.x);

  origuv.x += time/10;

  vec4 theNoise= texture(texNoise,origuv);

  uv.y += (theNoise.r)/5;
  uv.x = abs(uv.x);
  uv.y = abs(uv.y);

 
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  m.y += time + (fGlobalTime/10);
  m.x += ((fGlobalTime/30)*sin(m.y/100));
  float d = m.y;



 float ratio = (sin((m.x*50)+time*(-10))/sin(m.y*50))*500;



//  out_color = theNoise;

  out_color = vec4(ratio);


// out_color = f + t;
}

//  float f = texture( texFFT, d ).r * 100;
//  m.x += sin( fGlobalTime ) * 0.1;
//  m.y += fGlobalTime * 0.25;

//  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
//  t = clamp( t, 0.0, 1.0 );