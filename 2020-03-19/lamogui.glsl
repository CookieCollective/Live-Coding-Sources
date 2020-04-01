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

mat2 r(float a ){
  float c = cos(a);
  float s = sin(a);
  
  return mat2(c, s, -s, c);
}


float map(vec3 p) {
  vec3 g = p;
  g.xy = r(p.z*0.1) * g.xy;
  vec3 prout = g;
  float d = cos(g.x) + cos(g.y) + cos(g.z);
  
  float s = 10.0;
  g *= s;
  d = max(d,  (cos(g.x) + cos(g.y) + cos(g.z) ) /s);
  d = min(d, p.y + 0.2 - 0.1 * texture(texNoise, p.xz).r - 0.1 * cos(fGlobalTime + 2.0*p.z + 2.632 * p.x));
  return min(d, prout.y + 1.0 + 0.7 *texture(texNoise, p.xz * 0.2).r - 0.1 * cos(fGlobalTime + 2.0*prout.z + 2.632 * prout.x));
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
 
  float v = cos(fGlobalTime*3.0);
  
  vec3 ro = vec3(0.0,0.2 * abs(v),fGlobalTime);
  vec3 rd = normalize(vec3(uv, 0.7 - length(uv)));
  vec3 p = ro;
  
  float st = 1.0;
  for ( float i = 0.; i< 127.; ++i) {
    float d = map(p);
    if (abs(d) < 0.01) {
      st = i / 127.0;
      break;
    }
    p += rd * d;
  }
  
  uv = uv *0.8+ 0.2* r(fGlobalTime * 10.0) * uv;
  
  vec3 color = vec3((uv +0.5) * (st), 0.1) * (1.0) + (vec3(uv, 0.1) * exp( -0.1 * distance(p,ro))) + (vec3(uv, 0.1) * (1.0 -exp( -0.1 * distance(p,ro))));
  out_color = vec4(color, 0.0);
}