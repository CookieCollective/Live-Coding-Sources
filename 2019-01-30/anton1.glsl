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


mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}


#define PI 3.14159

float map(vec3 p)
{
  vec3 cp = p;
  p.z -= 10.;
    float time = fGlobalTime;

  float acc = 1000.;

  float BPM = 100. / 60.;

  float bump = sin(fract(time * BPM ) * PI - PI * .5) * .5 + .5;
  bump = pow(bump,2.);
  bump *= .35;

  p *= 1. - bump;

  for(float i = 1.; i <= 6.; i++)
{
  p.x = abs(p.x);
  p.xy *= rot(p.y * i * .15 + time);
  p.xz *= rot(p.y * i * .125 + time);
  p.y += p.x * .3;

  acc = min(acc,length(p) - (1. + i * .1));
  

}


  p = cp;

  float flo = p.y +10.;
  
  return min(acc, flo);
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.0,.01);
  return normalize(vec3(
  map(p + e.xxy) - map(p - e.xxy),
  map(p + e.xyx) - map(p - e.xyx),
  map(p + e.yxx) - map(p - e.yxx)
));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-7. + sin(fGlobalTime) * 2.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;

  float ti = floor(fGlobalTime ) + pow(fract(fGlobalTime), 2.);

  rd.xy *= rot(sin(ti * 2.) * .2);

























  float st = 0.;
  float cd = 0.;

  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += cd * rd * .75;
  }


  out_color = texture(cookie, uv * rot(fGlobalTime) + fGlobalTime * .12);


  if(cd < .01)
{
  vec3 norm = normal(cp);
  float li = dot(norm, vec3(-1.,1.,1.));

  

  out_color = vec4(li);

  out_color.xy *= rot(fGlobalTime + cp.x);
  out_color.xz *= rot(fGlobalTime + cp.z);

}
}




















