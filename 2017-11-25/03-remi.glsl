#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

#define T fGlobalTime

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

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  vec2 st = uv;
vec2 brUv = uv;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  uv *= 2.;
  uv.x += sin(T*1.5);
  uv.y = uv.y*sin(T)*5.;
  
  vec4 noise = texture(texNoise, uv);
 // noise *= 0.5;
 // noise += 0.5;

  st.y = st.y + noise.x * 0.05;

  vec4 pattern = texture(texTex4, st);

  pattern.r = pattern.g;
  st.y = st.y+(pattern.b * sin(T*2.)*.09);
  pattern = texture(texTex4, st);
  st *= cos(T)*5.;
  
  vec4 color = pattern-(noise*0.5);
  vec4 bricks = texture(texTex1, brUv);
  color.r += bricks.r;
  out_color = color;
}