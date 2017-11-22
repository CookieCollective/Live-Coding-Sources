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


float s(vec3 p)
{
  float theta = atan(p.z, p.x);
  float phi = asin(p.z);
  vec2 t = abs(vec2(phi, theta) / 3.1415);
  t += fGlobalTime * 0.1;
  return length(p) - .5 * (1.0 + 0.3 * texture(texNoise, t).x - 0.1*sin(mod(p.y, 3.1415*2.0) + fGlobalTime )) ;
}

float plane(vec3 p)
{
  return distance(p.y, -1.0);
}

float map(vec3 p)
{
  float d = s(p);
  d= min(d, plane(p));
  return d;
}


vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for (int i = 0 ; i < 96; ++i)
  {
    float d = map(p);
    if (abs(d) < 0.01)
      break;
    p += rd * d *0.9;
  }
  return p;
}

void main()
{
  vec2 v = gl_FragCoord.xy / v2Resolution;
   vec2 uv = v * 2.0 - 1.0; 
   uv.x *= v2Resolution.x/v2Resolution.y;

  vec3 ro = vec3(0, 0, -1.0);
  vec3 rd = vec3(uv, 1.0);

  vec3 p = rm(ro, rd);
  float d = distance(ro, p);
  out_color = vec4(vec3(exp(-d)), 1.0);


}