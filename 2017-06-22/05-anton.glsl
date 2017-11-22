#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float dist(float f, float w)
{
    return step(length(f),w) * step(length(f),w + .2);
}

vec2 rot(vec2 v, float a)
{
  float sa = sin(a); float ca = cos(a);
  return mat2(ca,-sa,sa,ca) * v;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

    float st =  pow(abs(fract(fGlobalTime) - .5),.9) ;

    float time = fGlobalTime + st;
  uv = rot(uv,length(uv) * sin(fGlobalTime * .1) * 3 + time );


  uv = mod(uv + .25, vec2(.5)) - .25;


    float a  = atan(uv.y,uv.x);
    a += sin(fGlobalTime * 2.) * 15;
    a = abs(a - .5) + .5;
  

    float s = texture(texFFTSmoothed,gl_FragCoord.x / v2Resolution.x).x;

    

  float c = distance(uv , vec2(.0,.0));

 
  float f = dist(c + a * .01, .1);
   
  
  uv.y += sin(uv.x * 4. + time) * .1;
  f = max(f, uv.y);

  f += step(abs(gl_FragCoord.y / v2Resolution.y - s),.01) ;

  vec4 c1 = vec4(.1,.5,.1,1.);
  vec4 c2 = vec4(.3,.1,.9,1.);

  out_color = mix(c1,c2,f);
}