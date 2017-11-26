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

vec4 plas( vec2 v, float time )
{
  float c = 0.3 + sin( v.x *55.)/(v.x+v.y) * 20.0*1/log(time) ;
  return vec4( sin(c * cos(time)), c * 0.72, cos( c * 0.1 + time /.3 ) ,1.0 );
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  //uv -= 0.4;
 
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  out_color = (vec4(0.9,0.8,0.7,1.)*plas(uv,fGlobalTime)) + vec4(sin(fGlobalTime*0.5*3.14), cos(fGlobalTime*0.5*3.14),sin(fGlobalTime*0.5*3.14),0.0);
    
out_color *= texture(texNoise,uv);
}