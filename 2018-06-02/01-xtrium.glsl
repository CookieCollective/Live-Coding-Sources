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

#define EPS .005

float map(vec3 p)
{
  float wp = p.y;

  mat2 r = mat2(cos(fGlobalTime * .1), sin(fGlobalTime * .1), -sin(fGlobalTime * .1), cos(fGlobalTime * .1));
  vec3 pp = p;
  pp.xz = r * pp.xz;

  pp.zx = r * pp.xy;

  wp += (0.15 + 0.0001 * sin(fGlobalTime * 0.33)) * -abs(sin(pp.x * (10. + 4. * p.x)));
  return wp + 0.3 * sin(cos(p.z) * 3.14159);
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(0., EPS);
  return normalize(vec3(map(p + e.yxx) - map(p - e.yxx), map(p + e.xyx) - map(p - e.xyx), map(p + e.xxy) - map(p - e.xxy)));
}

bool rm(vec3 ro, vec3 rd, out float tOut)
{
  float t = EPS;

  for(int i = 0; i < 128; ++i)
  {
    float d = map(ro+rd * t);

    if(d < EPS)
    {
      tOut = t;
      return true;
    }

    if(t > 128.0)
      return false;

    t += d;
  }

  return false;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 1.0, 5.0);
  vec3 rd = normalize(vec3(uv, -1.5));

  vec3 sc = vec3(0.25, 0.1, clamp(uv.y, 0.0, 1.0));
  out_color.rgb = sc;

  float tOut = 0.;
  if(rm(ro, rd, tOut))
  {
    vec3 col1 = normal(ro + tOut * rd);

    ro = ro + rd * tOut - EPS * 2.;
    rd = reflect(rd, col1);

    float sf = pow(dot(-rd, col1), 5.);

    vec3 col2 = out_color.rgb;
    float tOut2 = 0.;
    if(rm(ro, rd, tOut2))
    {
      col2 = normal(ro + tOut * rd);

      float d = pow(dot(-rd, col1), 5.);
      col1 = mix(col1, col2, 1.-d);
    }

    float diff = dot(col1, normalize(ro + rd * tOut2));

    out_color = mix(vec4(vec3(diff), 1.) + sc * (1.-diff), out_color, clamp(tOut / 32., 0., 1.));
  }
}
