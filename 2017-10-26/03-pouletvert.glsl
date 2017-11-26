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

float lol = 5.;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float circle(vec2 _uv) {
  return smoothstep(0.5, 0.51, length(_uv));
}

float untruc(vec2 _uv) {
  return step(.2, _uv.x) - step(.2 - _uv.x, _uv.x);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec4 backgroundColor = vec4(1., sin(uv.y), .0, .0);
  
  vec4 squareColor = vec4(.5, .5, .5, 1.);


  vec4 sunColor = vec4(0., 0., 1., 0.);
  
  uv += sin(fGlobalTime) * .25;
  
  uv *= mat2(cos(fGlobalTime * lol), sin(fGlobalTime * lol), -sin(fGlobalTime * lol), cos(fGlobalTime * lol));
  uv.x += sin(uv.y * 33. + fGlobalTime) * .033;
  
vec2 blob = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv.y += sin(blob.x * 10. * fGlobalTime) * .1;
  vec4 finalColor = mix(backgroundColor, sunColor, circle(uv));
   for(int i=0; i<10 ; i++) {
    finalColor += mix(finalColor, sunColor, circle(uv + vec2(i * .5, i + .33)));
  }

  finalColor = mix(finalColor, squareColor, untruc(uv));

  out_color = finalColor;
}