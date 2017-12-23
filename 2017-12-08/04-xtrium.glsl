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

float noise(vec2 p)
{
  return fract(sin(dot(p,p) * 49357.159));
}

float noise3(vec3 p)
{
  return fract(sin(dot(p.xy,p.yx) * 49357.159));
}

float map(vec3 p)
{
  float n = noise(floor(p.xz)) * 4.0;
  float nt = texture(texNoise, fract(p.xz*0.1)).r;
  float d1 = p.y + texelFetch(texFFTSmoothed, 4, 0).r + 0.1 * nt + 20.0 * n;


  float d2 = length(p - vec3(0.0, 1.5, -5.0 - fGlobalTime * 0.1)) - (n + (fract(texelFetch(texFFTIntegrated, 4, 0).r) * 0.5 + 0.5)) * 0.2 + 0.5 * noise3((p + vec3(fGlobalTime*0.1)) * 0.0001 + vec3(n * 0.5));

  return min(d1,d2);
}

vec3 skycolor(vec3 d)
{
  float t1 = smoothstep(-0.1, 0.0, d.y);
  vec3 cbase = vec3(0.4, 0.3, 0.25) * t1;

  vec3 c1 = vec3(0.7, 0.8, 0.9) * clamp(d.y, 0.0, 1.0);

  c1 += vec3(1.0, 0.5, 0.0) * 0.2 * clamp(1.0-d.y, 0.0, 1.0);

  return mix(cbase,c1,t1); 
}

bool rm(vec3 ro, vec3 rd, out vec3 hit)
{
  vec3 p = ro;

  for(int i = 0; i < 128; ++i)
  {
    float d = map(p);
    if(d < 0.005)
    {
      hit = p;
      return true;
    }

    p += rd * d;
  }

  return false;
}

vec3 nr(vec3 p)
{
  vec2 eps = vec2(.005, 0.0);

  return normalize(vec3(
    map(p + eps.xyy) - map(p - eps.xyy),
    map(p + eps.yxy) - map(p - eps.yxy),
    map(p + eps.yyx) - map(p - eps.yyx)
  ));
}

float shd(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  float shf = 1000.0;

  for(int i = 0; i < 32; ++i)
  {
    float d = map(p);
    shf = min(shf, d);
  }

  return smoothstep(0.0, 0.05, shf);
}

vec3 shade(vec3 ro, vec3 rd, vec3 hit)
{
  vec3 lp = vec3(0.0, 10.0, 30.0 - fGlobalTime * 0.1);
  vec3 V = normalize(hit-ro);
  vec3 N = nr(hit);
  vec3 L = normalize(lp-ro);
  vec3 H = normalize(L+V);

  float dist = distance(ro, hit);
  float att = 10.0 / (1.0 + dist * dist * .1);

  float dif = max(0.0, dot(N, L));
  
  float spec = max(0.0, pow(dot(N, H), 64.0));

  return vec3(dif+spec)*att * shd(hit + 0.05 * N, -L) + (N.y*0.5+0.5)*skycolor(-V)*0.2;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.0, 1.5, -fGlobalTime * 0.1);
  vec3 rd = normalize(vec3(uv, -1.5));

  vec3 cfinal = skycolor(rd);
  
  vec3 hit = vec3(0.0);
  if(rm(ro, rd, hit))
  {
    vec3 sh =shade(ro, rd, hit); 
    cfinal = mix(sh, cfinal, smoothstep(16., 32., distance(ro, hit)));
  }

  out_color = vec4(pow(cfinal, vec3(1.0/2.2)),1.0);
}