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


float circle(vec2 uv, float r) {
 
 return step(length(uv), r);
  
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  
  vec2 cv = uv -.5;
  cv.x *= v2Resolution.x/v2Resolution.y;

  vec2 st= cv;
  
  vec2 qr = st;

  cv.x *= fGlobalTime * cv.y;
  cv *= fract(cv*sin(fGlobalTime));

  st.x += cos(fGlobalTime*2.)*.5;
  
  //for(int i=0; i <10.; i++){
    
  //  st*= i ; 
  // } 
  qr += fGlobalTime*.2;
  
  float noiseCol = texture(texNoise, qr).r;

  vec4 col = vec4(circle(st, 0.5*noiseCol)*noiseCol);
  

  

  col.r = circle(cv, .5);

  out_color = col;
}