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
float bass;
float bassTime;


float obj(vec3 p)
{
  vec3 pp = p;
  pp.z = mod(p.z, 10.)-5.;
  float d=  -abs(p.x-1.)+3.+cos(length(pp.yz*3.)-fGlobalTime)*.1;


  return d;
}

float obj2(vec3 p)
{
  float d = length(p.xy-vec2(1.+cos(p.z),0.+sin(p.z)))-.1;


  return d;
}

float map(vec3 p)
{
  float d = dot(cos(p.xyz), sin(p.zxy))+1.;


  d += cos(p.z*10.)*bass*.2;
  d = min(d, obj(p));
  d = min(d, obj2(p));

  return d*.8;
}

vec3 normal(vec3 p)
{

  vec3 n;
  vec2 eps = vec2(0.01,0.);
  n.x = map(p) - map(p+eps.xyy);
  n.y = map(p) - map(p+eps.yxy);
  n.z = map(p) - map(p+eps.yyx);

  return normalize(n);
}


mat2 rotate(float v)
{
  float a = cos(v);
  float b = sin(v);
  return mat2(a,b,-b,a);
}

vec3 raymarch(vec3 ro, vec3 rd)
{
  vec3 p = ro;

  for(int i=0; i<64; i++)
  {
    float d = map(p);
    p += rd * d;
  }

  return p;
}

vec3 shade( vec3 ro, vec3 rd, vec3 p, vec3 n)
{
  vec3 ld = normalize(vec3(.1,1.,-.5));
  vec3 col = vec3(0.);

  col = vec3(1.) * max(0., dot(n,ld))*.3;
  col += mix(vec3(1.,.7,.1), vec3(.1,1.,.7), rd.x)*length(p-ro)*.05;

  return col;
}

void main(void)
{
  bassTime = 0.;
  for(int i=0; i<10; i++)
    bassTime += texelFetch(texFFTIntegrated, i,0).r;

  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  bass = 0.1;
  for(int i=0; i<10; i++)
    bass += texelFetch(texFFTSmoothed, i,0).r;

  vec3 ro = vec3(1.,0.,-fGlobalTime*.1-bassTime*.5);
  vec3 rd = normalize(vec3(uv*2.,-1.));
  rd.xy = rotate(bassTime*.01)*rd.xy;

  vec3 p = raymarch(ro,rd);
  vec3 n = normal(p);
  vec3 col = shade(ro, rd, p, n);


  for(int i=0; i<3; i++)
  if(obj(p)<.1)
  {
    ro = p;
    rd = reflect(rd,n);

    p = raymarch(ro+rd*.1,rd);
    n = normal(p);
    col = shade(ro, rd, p, n);
    
  }
  if(obj2(p)<.1)
    col += vec3(.1,.7,1.) * bass;

  out_color = vec4(col, 1.);
}