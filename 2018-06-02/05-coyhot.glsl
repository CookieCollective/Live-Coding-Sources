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
  
 

  float a = sin(p.z)/5.;
  float b = p.z/100.;
  float c = a*2.;
  float d = -fGlobalTime;
  float e = sin(d)/100000.;


  p.xz *= mat2 (cos(e),-sin(e),sin(e),cos(e));


  p.xy *= mat2 (cos(d),-sin(d),sin(d),cos(d));
  p.xy *= mat2 (cos(c),-sin(c),sin(c),cos(c));

  p.x += sin(p.z);


  p.xy *= mat2 (cos(a/b),-sin(a),sin(a),cos(a));
  p.xy *= mat2 (cos(a),-sin(a),sin(a),cos(a));


  p=mod(p,4)-2;

  p.z /= 5.;
  p.x += 1.75;
  
  p.z +=sin(p.y*25.+fGlobalTime*5.)/10.;
  p.z +=sin(p.x*25.+fGlobalTime*5.)/10.;



  return length(p)-1;

}


float tra(vec3 o, vec3 d)
{
  float t = 0.;

  for (int i=0; i<64; i++)
  {
    t += sce(o+d*t)*0.5;
  }
  return t;

}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float color = tra(vec3(cos(fGlobalTime),sin(fGlobalTime),fGlobalTime*10.), normalize(vec3(uv*2.5, 1.0)));
  float fog = 1/(1+color*color-1);

  out_color = vec4(vec3(color*fog),1.0);
  out_color += vec4(abs(sin(uv.x)),abs(sin(uv.y)/2.5),abs(sin(fGlobalTime)),1.0);

}



