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

float smin(float a, float b)
{
  float k = 32.;
  return -log( exp( -k/a) + exp( -k / b ) ) / k;
}
float obj( vec3 p )
{
  return cos(p.x)*cos(p.y)*cos(p.z) ;
}
float map(vec3 p)
{
  p.x += cos(p.z*2.)*.6;
  p.y += sin(p.z)*.3;
  float d = abs(p.y)-1.;
  d = min(d, abs(p.x)-1.);
  d += texture2D( texNoise, p.xy*.3).x*.8;
  d += texture2D( texNoise, p.xz*.3).x*.4;
  d += texture2D( texNoise, p.yz*.3).x*.2;
  return d*.5;
}

vec3 rm(vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<64; i++)
  {
    float d = map(p);
    p += rd * d;
  }

  return p;
}

vec3 normal( vec3 p )
{
  vec2 eps = vec2(0.001, 0.);
  vec3 n;
  float d = map(p);
  n.x = d - map(p - eps.xyy);
  n.y = d - map(p - eps.yxy);
  n.z = d - map(p - eps.yyx);
  return normalize(n);
}

float ao(vec3 p, vec3 n)
{
  float ao = 1.;
  for(int i=0; i<10; i++)
  {
    float h = float(i)*.1;
    ao -= abs( h - map(p+n*h)/10. );
  }
  return clamp( ao, 0., 1.);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float t = fGlobalTime;
  vec3 ro = vec3(0.,0., t*2.);
  vec3 rd = normalize(vec3(uv, 1.) );

  vec3 p = rm(ro,rd);
  vec3 n = normal(p);

  vec3 col = vec3(ao(p,n));
  col = mix(col, vec3(1.), min(length(p-ro)*.05, 1.));
  out_color = vec4(col,1.);
}