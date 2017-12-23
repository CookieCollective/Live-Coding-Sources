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


float a(vec3 p)
{
  return cos(p.x)+cos(p.y)+cos(p.z);
}

float map(vec3 p)
{
  float d = a(p);
  vec3 pp = p;
  pp = mod(pp, vec3(1.))-.5;
  d = max(d, -(length(pp)-.5));
  pp = mod(pp, vec3(.5))-.25;
  d = max(d, -(length(pp)-.25));
  pp = mod(pp, vec3(.25))-.125;
  d = max(d, (length(pp)-.125));

  return d;
}

vec3 normal(vec3 p)
{
  vec3 n;
  vec2 eps = vec2(0.01, 0.);
  n.x = map(p) - map(p-eps.xyy);
  n.y = map(p) - map(p-eps.yxy);
  n.z = map(p) - map(p-eps.yyx);
  return normalize(n);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv = uv*2.-1.;
  uv.x *= v2Resolution.x/v2Resolution.y;
  
  vec3 ro = vec3(0.,0.,fGlobalTime);
  vec3 rd = normalize(vec3(uv, 1.));

  vec3 p = ro;
  float glow = 0.;
  for(int i=0; i<64; i++)
  {
    float d = map(p);
    p += rd *d ;
    glow += 1./64.;
    if(d<0.01)
      break;
   }
  vec3 n = normal(p);

  vec3 col = vec3(1.) * max(0., dot(n, normalize(vec3(0.,1.,-1.)))) * length(ro-p)*.05;
  
  col += vec3(1.,.7,.1) * glow*2.;
out_color = vec4(col, 1.);
}