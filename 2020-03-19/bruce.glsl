#version 410 core
uniform float fGlobalTime;
uniform vec2 v2Resolution;
uniform sampler1D texFFT; 
uniform sampler2D texNoise;
uniform sampler2D texTex1;
layout(location = 0) out vec4 out_color; 
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  vec4 fromage = texture(texNoise, uv-m+sin(fGlobalTime)+0.5);
  float raclette = uv.x ; 
  uv += pow(length(uv), raclette* fromage.x);
  m.y = 1 / length(uv) * .2;
  float r = sqrt(dot(uv,uv));
  float w = (sin(fGlobalTime)+ 3.0*cos(fGlobalTime + 15.0*m.y)/2.0);
  float col = 0.0;
  float d = pow(dot(uv,uv),12.*cos(fGlobalTime)+0.975);
  col = .1/length(mod(uv, 1.0)-sin(fGlobalTime*d*w*m)+0.41);
  float coscoscos = cos(d) + cos(m.x) + cos(fromage.r);
  col += smoothstep(-2., 2., d-fromage.g+mod(uv,2.0).r * coscoscos);
   
  float camembert = fromage.r * m.y+r * abs(sin(uv.x));
  out_color = vec4(camembert, fromage.r, col,1.0)*vec4(0.5,camembert,0.9,1.0);
}