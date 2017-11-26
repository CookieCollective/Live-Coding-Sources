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

float fbm(vec2 p)
{
float a = .25;

  float time = fGlobalTime * .1;

  float c = cos(a); float s = sin(a);
  mat2 m = mat2(c,-s,s,c);
  float acc = 1.;
  float f = texture(texNoise,p / acc + time).r * acc; p *=m; acc *= .99;
  f += texture(texNoise,p / acc ).r * acc; p *=m * .1235 + time; acc *= .9;
  f += texture(texNoise,p / acc ).r * acc; p *=m * .2369 + time; acc *= .09;
  f += texture(texNoise,p / acc ).r * acc; p *=m * 125. + time; acc *= .09;
texture(texNoise,p).r; p *=m;
  return f;
}



void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float f = 0.;
  
  float a = .1 + length(uv * .25);
  float c = cos(a); float s  = sin(a);
  uv *= mat2(c,-s,s,c);

  float amp = sin(length(uv)  * 10.- fGlobalTime) *.5 +.5;
  amp = amp * .4 + .7;
  //f = 1. - length(uv);

  float st = sin(fGlobalTime) * .5 + .5;

  st = st * .4 + .5;

  f =  1. - smoothstep(fbm(uv), st - .05,st + .05);

  
    vec3 col = .45 * vec3(sin(f *.25) * .4 + .4, cos(f*1.1) * .5 + .3, sin(f * 4) * .5 + .7);


  

  out_color = vec4(col,0.) * amp;
//  out_color = texture(texTex1, vec2(fbm(uv),fbm(uv.yx)));
}