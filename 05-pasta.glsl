#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
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


float coucoulecercle(vec2 uv, vec2 center, float r)
{
  return length(uv - center) < r ? 1 : 0;
}

void main(void)
{
  float nosewidth = 0.5;
  float noseheight = 0.1;
  float baser = 0.1;
  float dr = 0.1;
float dt = 1.2;
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  float t = 1 - mod(pow(fGlobalTime, 2), dt) / dt;
  float r = baser + t * dr;
  vec4 bgcol = vec4(.0);
  vec4 forcol = vec4(1.0);
  float c = coucoulecercle(uv, vec2(-nosewidth * 0.5, noseheight), r) + coucoulecercle(uv, vec2(nosewidth * 0.5, noseheight), r);

  vec2 alttexuv = uv + dt * fGlobalTime * 0.5;
  forcol = texture(texNoise, alttexuv);
  
  float angle = atan(uv.x, uv.y) + mod(fGlobalTime, 3.1416);
  float anglecol = mod(angle, 1.0) < 0.5 ? 1 : 0;


/*
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = clamp( t, 0.0, 1.0 );
*/
  vec2 uvPegasus = uv * -0.5 + vec2(0.45, 0.5);
bgcol = texture(texPegasus, uvPegasus);
  out_color = mix(bgcol, forcol, c);
}