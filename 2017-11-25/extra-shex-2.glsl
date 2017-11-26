#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNogozon;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float rep(float p, float r)
{
  float hr = r * .5;
  return mod(p + hr,r) - hr;
}

mat2 rot(float a)
{
  float c = cos(a); float s = sin(a);
  return mat2(c,-s,s,c);
}

#define PI 3.14

float map(vec3 pos)
{
  float phi = asin(pos.z) + 1.0 * fGlobalTime;
  float theta = atan(pos.y, pos.x);
  float v = texture(texNoise, vec2(theta, phi)).x;
  return length(pos /*+ vec3(0.0, 0.05 * cos(10.0 * fGlobalTime + 50.0 * pos.y), 0.0)*/) - (0.5 + v * 0.1); 
  
 /*
  pos.xy *= rot(.05 * pos.z);
  
  pos += 1.5 ;

  float t = fGlobalTime;

  float ft = floor(t);
  float mt = t - ft;

  t = ft + sin( mt * PI - PI/2.) * .5 + .5;

  float re = 3.;

  pos.xy *= rot(fGlobalTime * .3);
  pos.yz *= rot(fGlobalTime * .5);

  //pos.z += t * re;
  pos.z += fGlobalTime * 4.;

  pos.x = rep(pos.x , re);
  pos.y = rep(pos.y , re);
  pos.z = rep(pos.z , re);

  return min(min(length(pos.xy), length(pos.yz)),length(pos.xz))-.25;*/
  
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.1,0.);
  return normalize(
    vec3(
      map(p - e.xyy) - map(p + e.xyy),
      map(p - e.yxy) - map(p + e.yxy),
      map(p - e.yyx) - map(p + e.yyx)
    )
  );
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0,0,-2);
  vec3 rd = normalize(vec3(uv,1));
  vec3 p = ro;
  
  for (int i = 0; i < 64; ++i)
{
  float d = map(p);
  if (abs(d) < 0.01)
  {
    break;
  }
  p = p + rd * d;
}

  vec3 color = vec3(exp(-distance(ro, p) * 0.7));
  float pi2 = 0.5 * 3.14159;
    float phi = asin(p.z) / pi2 + 1.0 * fGlobalTime;
  float theta = atan(p.y, p.x) / pi2;
  vec3 vcolor = texture(texTex2, vec2(theta, phi)).rgb;
  out_color = vec4(vcolor, 1);
  color += vcolor;

/*
  float id = 0.;


  for(float st = 0.; st < 1.; st += 1. / 128.)
  {
    float cd = map(cp);
    if(cd < .01)
    {
      id = 1. - st;
      break;
    }

    cp += rd * cd * .5;
  }

  float f = id;

  vec3 ld = normalize(cp - vec3(0));

  vec3 norm = normal(cp);
  
  out_color = vec4(f * clamp(dot(norm, ld),0.,1.) * 1.5);
  out_color *= 4.;
  out_color = floor(out_color);
  out_color /= 4.;*/
}