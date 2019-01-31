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

vec2 rot(vec2 v, float a)
{
  return mat2(cos(a), sin(a), -sin(a), cos(a))*v;
}

float map(vec3 p)
{
  p.xy = rot(p.xy, .1*p.z);

  vec3 q = mod(p, 12.) -6;

  return length(q) - 5.;
}

vec3 gn(vec3 p)
{
  vec2 e = vec2(0., 0.001);
  return normalize(vec3(map(p-e.yxx)-map(p+e.yxx),
                        map(p-e.xyx)-map(p+e.xyx),
                        map(p-e.xxy)-map(p+e.xxy)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv *= 2.;
  uv -= 1.;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv = rot(uv, -0.5*fGlobalTime);

  vec3 o = vec3(0., 0., 10.*fGlobalTime);
  vec3 p = o;
  vec3 rd = normalize(vec3(uv,1.));

  int i = 0;

  for(i = 0; i < 64; ++ i)
  {
    float d = map(p);
    p += rd*d;
    if(d<0.001)
      break;
  }

  float c1 = float(i)/64.*4.;

  vec3 n = gn(p);

  vec3 rd2 = reflect(rd, n);

  vec3 p2 = p+.1*rd2;

  for(i = 0; i < 64; ++ i)
  {
    float d = map(p2);
    p2 += rd2*d;
    if(d<0.001)
      break;
  }

  float c2 = float(i)/64.*4.;

  vec3 co = mix(vec3(c1*c2), vec3(0., 0.3, 0.4), 1.-exp(-distance(p, o)*.035));

  out_color = vec4(co, 1.);;
}