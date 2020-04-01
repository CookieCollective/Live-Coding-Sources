#version 410 core

uniform float fGlobalTime;
uniform vec2 v2Resolution; 
uniform sampler1D texFFT;
uniform sampler2D texNoise;
uniform sampler2D texTex1;

layout(location = 0) out vec4 out_color; 
#define time fGlobalTime

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y) * 4.0;
  uv -= 1.95;// + abs(sin(time)-0.99);
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
vec3 c = vec3(0.2);
  float r = length(uv)*2.0 + (sin(time) -0.5) ;
  float a  = atan(uv.y, uv.x);
  float f = abs(cos (a * 5.));
  vec3 col = vec3(0.0);
  for(int i=0;i<3;i++) {
    uv += length(uv);
      col[i] = 0.01/length(abs(mod(uv,1.)-0.24));
      
    }
  col = 1.0 - normalize(col*col);
  c -= fract(uv.x +time);
  c -= vec3( 0.5 - smoothstep(f, f * cos(r*time*0.03), r) );
  out_color = vec4( vec3(c.r + col.r,col.g * sin(time)-0.6,c.b + col.b), 1.0);
}