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

float bass, bassTime;



float fbm( vec2 p )
{
  float a = texture(texNoise, p).r*.5;
  a += texture(texNoise, p*2.).r*.25;
  a += texture(texNoise, p*4.).r*.125*bass;
  a += texture(texNoise, p*8.).r*.025;
  return a;
}

float ocean( vec3 p)
{
  return p.y+12.+fbm(p.xz*0.01+fGlobalTime*.01)*1.;
}
float map(vec3 p )
{
  float d = p.y + fbm(p.xz*.005)*70.;
  d = min(d, ocean(p));
  return d;
}

vec3 raymarch( vec3 ro, vec3 rd)
{
  vec3 p = ro;
  for(int i=0; i<64; i++)
  {
    float d = map(p);
    p += rd * d;
  }

  return p;
}

vec3 normal(vec3 p)
{
  float d = map(p);
  vec2 eps = vec2(0.01, 0.);
  vec3 n;
  n.x = d - map(p-eps.xyy);
  n.y = d - map(p-eps.yxy);
  n.z = d - map(p-eps.yyx);

  return normalize(n);
}

vec3 sky(vec3 rd, vec3 ld)
{
  vec3 col = vec3(0.);
  col += texture(texNoise, rd.xz / rd.y*.05-fGlobalTime*.01).r*2.-1.;
  col += (texture(texNoise, rd.xz / rd.y*.2+fGlobalTime*.25).r*2.-1.)*.5;

  vec3 gradient = mix( vec3(1.), vec3(.5,.7,1.), clamp((rd.y+.3)*5., 0., 1.));
  col = mix(gradient, col, clamp((rd.y)*5., 0., .2));
 
  col += vec3(1.,.7,.1) * pow(dot(rd, ld), 300.);
  return col;
}


float shadow(vec3 p, vec3 ld)
{
    vec3 ps = raymarch(p+ld*.1, ld);

    return length(p-ps)>10. ? 1. : 0.;
}

vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n)
{
  vec3 ld = normalize(vec3(0.1,1.,1.5));
  vec3 col = vec3(0.);
  

  vec3 dif = vec3(1.,.7,.1) * max(0., dot(n, ld));

  vec3 amb = vec3(0.,0.,.1) * max(0., dot(n, vec3(0.,1.,0.)));
  col = dif + amb;

  float shad = shadow(p, ld);

  col *= vec3(1.)*shad;

  col = mix(col, sky(rd, normalize(vec3(0.1,1.,3.5))), vec3(1.)*min(1., length(ro-p)*.0025));
  col = mix(col, vec3(1.), vec3(1.)*clamp(-pow(p.y,3.)*.0002,0.,1.));


  return col;
}

const float pi = 3.141592653589;
void main(void)
{


  bass = 0.;
  bassTime = 0.;

  for(int i=2; i<10; i++)
  {
    bass += texelFetch(texFFTSmoothed, i, 0).r/float(i);
    bassTime += texelFetch(texFFTIntegrated, i, 0).r/float(i);

  }

  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0., 5.,fGlobalTime + bassTime*30.);
  vec3 rd = normalize( vec3( uv , 1. ) );
  vec3 p = raymarch(ro,rd);
  vec3 n = normal(p);

  vec3 col = shade(ro,rd,p,n);

  if(ocean(p)<.1)
  {
    ro = p;
    rd = reflect(rd,n);
    p = raymarch(ro+rd*.1,rd);
    n = normal(p);

    col = shade(ro,rd,p,n);

  }

  out_color = vec4(col, 1.);
}