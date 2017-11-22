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

 vec3 greenA = vec3(34, 117, 76);
 vec3 greenB = vec3(181, 230, 29);

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );



  // Alors, c'est l'histoire d'un type qui rentre dans un café et plouf !

  // Un jour je suis allé sur la Lune

  // oh putain c'était le bordel



}
void main(void)
{
  greenA /= 255.;
  greenB /= 255.;
  vec3 white = vec3(1.,1.,1.);

  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 uv2 = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  //uv2 = distance();

  float radius = 0.25;
  radius += cos(atan(uv.x, uv.y));
  float l = distance(uv, vec2(.0, .0));
  l = step(radius + sin( fGlobalTime * 2. ) * .1, l);
  
  vec2 move = uv;
move.x *= 2.;
  move.y *= sin( fGlobalTime * 10.) + 1.5;
  float c = distance(move, vec2(.0, .0));
  c = step(.1, c);

  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = clamp( t, 0.0, 1.0 );
  
  vec3 caca = mix(greenB, greenA, l * c);

  out_color = vec4(mix(caca, white * fGlobalTime * .001, uv.y) , .1);
}