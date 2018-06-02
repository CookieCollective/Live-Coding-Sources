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

float sce (vec3 p)
{
  float a = fGlobalTime;
  float b = sin(a)*p.x-cos(a)*p.y;
  float c = p.z*1.25;


  p.y += cos(b+fGlobalTime);
  p.x += sin(b+fGlobalTime);


  p.xy *= mat2(cos(c), -sin(c), sin(c), cos(c));
 

  p.xy *= mat2(cos(b), -sin(b), sin(b), cos(b));
 
 p = mod(p,4)-2;

 p.z += sin(p.y*20.+a*5.)/10.;
 p.z += sin(p.x*20.+a*5.)/10.;

 return length(p)-1;
}


float tra (vec3 o, vec3 d)
{
  float t = 0.;

  for (int i=0;i<128;i++)
  {
    t += sce(o+d*t)*0.35;  
  }
  return t;
}



void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 uvorig = uv;

  vec4 noise = texture (texNoise,uvorig);

  vec4 lines = texture (texTex2,uvorig);


  uv += cos(noise.r+fGlobalTime)/5.;

  uv += cos(lines.r+fGlobalTime)/20.;


  float color = tra(vec3(sin(fGlobalTime),cos(fGlobalTime)/2,fGlobalTime*4.),normalize(vec3(uv*10.,1.0)));
  float fog = 1/(1+color*color-1);

  out_color = vec4(vec3(color*fog*4.),1.0);


  out_color *= vec4(uv.x+1.0,uv.y+0.5,abs(sin(fGlobalTime*5.)),1.0);
}