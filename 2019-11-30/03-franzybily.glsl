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

float RND(float n){
  
    float r = sin(n+12345.67)+sin(n*4.+3256.);
    return  fract(r);
  
}

float randd(float n){
  
  float c = fract(n);
  return mix(RND(n),RND(n+1),c);
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv *= 2.;
  float t = fGlobalTime*2.;
  t = floor(t) + smoothstep(0.,1.,fract(t));
  
  
  float V = 0.;
  vec3 C = vec3(0);
  int count = 10;
  for(int i = 0; i<count;i++){
   
    
    float gil = sin(t+uv.x+i)*0.5;
  
  
  float nusan = gil + sin(i*2.23+t)+cos(uv.x + t*2.2);
  float r = randd(uv.x+t+uv.y);
  float width = 0.05+r*0.05 + (sin(t*4.)*fract(uv.x)*0.5+0.5)*0.2;
  float S1 = step(nusan + width,uv.y-i*0.01);
  float S2 = step(nusan - width,uv.y);
  V += S2-S1; 
  C += vec3(sin(V)*0.02,cos(V*0.02)*0.1,0.);
  C += RND(t*10.+i)*0.02  ; 

    
  }
  float flopine = 0.;
  C = vec3(1.)-C;
  C = pow(C,vec3(5.2));
  
  out_color = vec4(C.rrr,1.);
}