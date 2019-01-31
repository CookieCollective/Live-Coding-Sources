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

#define time fGlobalTime
mat2 rot(float v)
{
  float a = cos(v);
  float b = sin(v);

  return mat2(a,b,-b,a);
}


float fbm( vec2 p )
{
  float d = texture2D(texNoise, p).r *.5;
  d += texture2D(texNoise, p*2.).r *.25;
  d += texture2D(texNoise, p*4.).r *.125;

  return d;

}

float flotte(vec3 p)
{
  //p.xy = rot(p.z)*p.xy;
  return -abs(p.y)+.7 + fbm(p.xz*.1)*.1;
}

float terrain( vec3 p )
{
  p.xy = rot(p.z)*p.xy;
  float d = -abs(p.y)-1.;
  d += fbm(p.xz*.05)*10.;

  return d;
}

float map(vec3 p)
{

  float d = min(terrain(p), flotte(p));

  return d*.6;
}


vec3 normal(vec3 p)
{
  vec2 eps = vec2(0.01, 0.);
  float d = map(p);
  vec3 n;
  n.x = d - map(p-eps.xyy);
  n.y = d - map(p-eps.yxy);
  n.z = d - map(p-eps.yyx);

  return normalize(n);
}
vec3 raymarch(vec3 ro, vec3 rd)
{

  vec3 p = ro;

  for(int i=0; i<64; i++)
  {
    p += rd * map(p);
  }

  return p;
}

vec3 shade(vec3 ro, vec3 rd, vec3 p , vec3 n)
{

  vec3 ld = normalize(vec3(0.5,1.,1.));
  vec3 albedo = mix(vec3(.2,.1,.1)*2., vec3(0.5,1.,0.), pow(abs(n.y), 4.));

  float shad = step(1.,length(raymarch(p+ld*.1, ld)-p));
  vec3 dif = vec3(1.,.7,.1) * max( dot(n, ld), 0.) ;
  vec3 amb = vec3(0.,0.,.1);

  vec3 col = albedo * (dif+amb);


  return col;

}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv *= 2.;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,time);
  vec3 rd = normalize( vec3(uv, 1.));

  rd.xy = rot(time*.1) * rd.xy;
  vec3 p = raymarch(ro,rd);
  vec3 n = normal(p);
  vec3 col = shade(ro,rd,p,n);
  if(flotte(p)<terrain(p))
  {
    vec3 rro = p;
    vec3 rrd = reflect(rd,n);

    vec3 rp = raymarch(rro+rrd*.1,rrd);
    vec3 rn = normal(rp);

    vec3 rcol = shade(rro, rp, rp, rn);

    col = vec3(.5,1.,2.)*rcol;
  }

  col = mix(col, vec3(1.), 1.-exp(-length(p-ro)*.1));

  col = pow(col, vec3(1./2.2));
  out_color = vec4(col, 1.);
}