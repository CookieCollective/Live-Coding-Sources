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

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

/*
vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
*/

float circle(vec2 p, float r)
{
return 0.0;
  // length(p) 
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

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
  out_color = f + t;
  */

  vec4 c = vec4(1.0,0.5,0.0,1.0);

  float bx = uv.x;
  bx += uv.x*uv.y * sin(mod(fGlobalTime*0.01,0.2));
  c.y += (mod(bx + fGlobalTime*0.01, 0.10)) < 0.06 ? 0.2 : 0.0;
  //c.z += (mod(uv.y + fGlobalTime*0.01, 0.10)) < 0.06 ? 0.2 : 0.0;

  float r = 0.3;
  r += texture(texFFTSmoothed, 0.1).x * 1.0;

  if (length(uv.xy) < r)
  if (length(uv.xy - vec2(1.2,0.6)) < 1.4)
     uv.y -= texture(texTex2, uv.xy + vec2(fGlobalTime*uv.y-2,uv.x)).r * 0.2;

  if (length(uv.xy) < r)
  {
     c.x = 0.0;
     c.y += texture(texNoise, uv.xy).r;
  }

  for (float z = 0.0; z < 1.0; z += 0.1)
  {
    float len = length(uv.xy-vec2(0.09/(z+z),0.09*z+sin(fGlobalTime)*0.05));
    float s = 0.0;//sin(texture(texTex1,vec2(0.1,uv.y)).x);
    if (len > r*(1.4 + s*0.0) && len < r*1.5)
    {
       c.z += 0.3;
       c.y += 0.8;
    }

    if (length(uv.xy - vec2(1.2,0.6)) < 1.4)
    {
       c.x += 0.8;
    } 

    c.z += uv.x * 0.2;
  }

  //circle(vec2(0.5,0.5), 0.1);

  out_color = c;
}