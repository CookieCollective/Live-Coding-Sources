#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
mat2 r(float a)
{
  float c= cos(a);
  float s = sin(a);
  return mat2(s, -s , c ,s);
}

float m(vec3 p)
{
p.xy *= r(10.0 *3.1415 * fGlobalTime);
  float d = cos(p.x) + cos(p.y) + cos(p.z);

  
  return d;
}
vec3 r(vec3 ro, vec3 rd, out float st)
{
  vec3 p = ro;
for (float i = 0.0; i <  64.0; i++)
{
  float d = m(p);
  if (abs(d)<0.01)
{
  st = i /64.0;
  break;
}
  p+= rd * d;
}
  return p;
}

vec3 s(vec3 ro, vec3 p)
{
  vec3 c = vec3(exp(-distance(ro, p) * 0.1));
 c *= vec3(1.0 ,0.0, 0.0);
  return c;
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);



  vec3 rd = normalize(vec3(uv, 1.0));
  vec3 ro = vec3(0.0, 0.0, 10.0* texture(texFFTIntegrated, 0.01).x);
float st = 1.0;
  vec3 p = r(ro, rd, st);
  vec3 c = s(ro, p);
   c = mix (c, texture(cookie, p.xz + fGlobalTime).rgb, 0.5);

p.xz = r(fGlobalTime) * uv;
  c = mix (c, texture(descartes, p.xy).rgb, 0.3);
c += fract(fGlobalTime * 10.0);
  out_color = vec4(c, 1.0);
}