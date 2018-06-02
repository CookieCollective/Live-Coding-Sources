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

float sce(vec3 p)
{
  float a = fGlobalTime;



  p.y -= p.z;
  p.x += p.z;

  p.z -= fGlobalTime/350.;
  p.yz *= mat2(cos(a*2), -sin(a*2), sin(a*2), cos(a*2));
  p.xz *= mat2(cos(a), -sin(a), sin(a), cos(a));

  p.xy *= mat2(cos(a), -sin(a), sin(a), cos(a));

  p = mod(p,3)-1.5;

  p.z += floor(sin(p.y*20.)/5.);
  p.z += floor(sin(p.x*20.)/5.);

  return length(p)-1;
}

float tra(vec3 o, vec3 d)
{
  float t = 2.;

  for (int i=0;i<128;i++)
  {
    t += sce(o+d*t)*0.25;
  }
  return t;
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 uvorig = uv;

  vec4 noise = texture(texNoise,uvorig);
  vec4 disto = texture(texTex3,uvorig);


  uv.x += fGlobalTime/50000.;
  uv.y += fGlobalTime/50000.;

  uv += noise.r /5.;
  uv += disto.r /40.;


  float color = tra(vec3(0.,0.,-1+fGlobalTime/250.),normalize(vec3(uv*6.,1.0)));
  float fog = 1/(1+color*color-1.0);



  out_color = vec4(vec3(color*fog),1.0);
  out_color += vec4(sin(uv.x),sin(uv.y),abs(sin(fGlobalTime)),1.0); 

}