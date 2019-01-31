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

float h(vec2 p)
{
  return cos(p.x + sin(0.1* p.x + cos( p.x))) +  0.1 * sin( 2.6 * p.y);
}

float g(vec3 q, vec3 p)
{
  q.y += 10.0 * texture(texFFTIntegrated, 0.01).x;
  float per = 3.0;
  vec2 id = q.xz / per + per * 0.5;
  q = mod(q, per) - 0.5 * per;
  return 1.0 - length(q);
}


float map(vec3 p)
{
  float d = p.y + 2.0 -  h(p.xz);
  d = min(d, g(p, p));
  return d;
  return cos(p.x) + cos(p.y) + cos(p.z);
}

vec3 rm(vec3 ro, vec3 rd, out float st)
{
  st = 1.0;
  vec3 p = ro;
  for (float i = 0.0; i < 64.0; i++)
  {
    float d = map(p);
    if (abs(d) < 0.01)
    {
      st = i / 64.0;
      break;
    }
    p += d * rd * 0.9;
  }
  return p;
}

vec3 shade(vec3 ro, vec3 p, float st)
{
  float t = exp(-distance(ro, p) * 0.1);
  vec3 c = vec3(t) * (1.0 - st);
  c *= mix(texture(texChecker, p.xz).xyz, c,  1.0 -t);
  c = mix(vec3(0.0, 2.0, 2.0), c, 2.0* t);
  //c = vec3(exp(-distance(ro, p) * 0.1));
  return c;
}

vec3 n(vec3 p)
{
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), 
map(p + e.yxy) - map(p - e.yxy),
 map(p + e.yyx) - map(p - e.yyx)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv.x *= v2Resolution.x/v2Resolution.y;
   

  vec3 ro = vec3(0.0, 0.0, fGlobalTime);
  vec3 rd = normalize(vec3(uv, 1.0));
  float st = 1.0;
  vec3 p = rm(ro, rd, st);
  vec3 c = shade(ro, p , st);

  vec3 n = n(p);
  vec3 rd2 = reflect(rd, n);
  vec3 ro2 = p + 0.1 * n;
  vec3 p2 = rm(ro, rd2, st);
  c = shade(ro, p2, st);
  //c = mix(c, shade(ro, p2, st), 0.8);
//c = mix(c, vec3(0.0, 1.0 ,1.0), distance(ro, p));

  out_color = vec4(c, 1.0);
}