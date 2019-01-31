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
vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float map( vec3 p) {
  float d =  dot( cos(p.xyz), sin(p.zxy)) + cos(p.y*20.)*.01+.75;
  d = min(d, length(p.xy+vec2(cos(p.z)-1., sin(p.z)))-.1);
  return d;
}

mat2 rot(float v)
{
  float a = cos(v);
  float b = sin(v);

  return mat2(a,b,-b,a);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  vec2 v = uv;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv = uv*2.;
  float impuls = pow(texture2D(texNoise, vec2(0., time*1.1)).r, 10.)*5000.;
  uv.x +=  impuls * (texture2D(texNoise, vec2(uv.y, time*.1)).g*2.-1.)*.3;

  uv = abs(uv);
  uv = rot(time*.5) * uv;
  uv = abs(uv);
  uv = rot(-time*.25) * uv;
  uv = abs(uv);
  uv += vec2(cos(time)*.1);
  uv = rot(-time*.175) * uv;
  uv = abs(uv);
  uv = rot(time*.175) * uv;
  uv = abs(uv);
  uv = rot(-time*.25) * uv;
  uv = abs(uv);

  uv = mix(uv, v*2.-1., max(0.,cos(time*.1)));

  vec3 ro = vec3(1., 0., fGlobalTime);
  vec3 rd = normalize( vec3(uv, 1.));

  vec3 p = ro;

  for(int i=0; i<64; i++) {
    p += rd * map(p);
  }
  vec3 col = vec3(1.,.7,.3) * max(0.,map(p)-map(p+vec3(-1.,-.7,.25)*.5))*3.;
  col += vec3(v.x*cos(time),1.+uv.y*.5*sin(time)-v.x*.5,.5) * (1.-exp(-length(ro-p)*.1));
  col *= 2.*mix(vec3(cos(uv.x+time*.1),cos(uv.y+uv.x+time),sin(time))*.5+.5, vec3(1.), 1.-5.*impuls) * exp(-length(ro-p)*.1);

  if( abs(cos(length(uv)-time*.82)) < .1) {
    col = col.brg;
  }
  if( abs(sin(length(uv+.5)+time*.82)) < .1) {
    col = col.gbr;
  }

  col *= pow(v.x*v.y*(1.-v.x)*(1.-v.y), .15);

  out_color = vec4(col, 1.);
}