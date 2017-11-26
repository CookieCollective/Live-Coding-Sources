#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
/*
vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}*/

float bass()
{
   float f = 0.0;
  for (int i = 0; i < 32.0; ++i)
  {
    f = max(f, texture(texFFTIntegrated, float(i)/1024.0).x);
  }
  return f;
}

float b;

float bass2()
{
   float f = 0.0;
  for (int i = 0; i < 32.0; ++i)
  {
    f = max(f, texture(texFFTIntegrated, float(i)/1024.0).x);
  }
  return f / (32.0 * 1024.0);
}

float map(vec3 p) 
{
  float d = cos(p.x) + sin(p.y)  + 0.1 * sin(25.0 * p.y + 0.1 * b)  + cos(p.z);
  return min (d, length(p.xy + 0.05 * vec2(0.2 + cos(p.z), - 8.0 + sin(p.z)) - 0.05)) ;
}

vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for (int i = 0 ; i < 16; ++i)
   {
      p += map(p) * rd * 0.8;
    } 
  return p;
}

vec3 grad(vec3 p)
{
 vec2 e = vec2(0.001, 0.0);
  return normalize(vec3 
 (
    map(p + e.xyy) - map(p - e.xyy),
map(p + e.yxy) - map(p - e.yxy),
map(p + e.yyx) - map(p - e.yyx)
));
}

void main(void)
{
 b = bass();
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 1.0, 2.0 * fGlobalTime + 10.0 * b);
  vec3 rd = normalize(vec3(uv, 0.7 - length(uv)));

  vec3 p = rm(ro, rd);

  float s = exp(-distance(ro, p) * 0.1);
  vec3 color = vec3(s);
  vec3 n = grad(p);
  color *= (n * 0.5 + 0.5).xzy;

  vec3 p2 = rm(p + n * 0.1, reflect(rd, n));
  vec3 n2 = grad(p2);
   float s2 = exp(-distance(ro, p) * 0.1);
  vec3 color2 = exp(-distance(ro, p) * 0.1) * (n2 * 0.5 + 0.5);

  color = mix(color, color2, 0.1);
  out_color = vec4(color, 1.0);
}