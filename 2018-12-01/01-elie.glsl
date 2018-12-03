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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4(sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float map(vec3 p) {
  p.x *= p.z;
  return length(p) - 0.1;
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  vec2 uv0 = uv;
  uv.x += smoothstep(0.95, 1.0, sin(fGlobalTime * 10.0)) * 0.1;
  uv.x -= smoothstep(0.95, 1.0, sin(fGlobalTime * 25.33)) * 0.1;
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 s = vec2(1.0, v2Resolution.y / v2Resolution.y) * 40.;
  uv = round(uv * s) / s;
  vec2 xy = fract(uv0 * s);

  vec3 p = vec3(0.0, 0.0, 5.0);
  vec3 v = normalize(vec3(uv, -1.0));
  float i = 0.0;
  for (; i < 1.0 ; i+=0.01) {
    float d = map(p);
    p += v * d;
  }

  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = clamp( t, 0.0, 1.0 );
  //out_color = vec4(i);

  float alpha = atan(uv.y, uv.x);
  float aa = alpha * 0.01 ;
  vec4 c0 = sin(aa) * vec4(1.0, 1.0, 0.0, 1.0) + cos(aa) * vec4(0.0, 1.0, 0.0, 1.0);
  c0 = sin(aa * 0.05) * vec4(1.0, 0.0, 0.0, 0.0);
  c0 += sin(aa * 0.1 + fGlobalTime * 0.001) * vec4(1.0, 0.5, 0.0, 0.0);
  out_color = sin(c0 * (alpha + fGlobalTime) * 10.0);

  float tt = mod(fGlobalTime, 2.0) - 1.4;
  tt += smoothstep(0.0, 1.0, sin(uv0.y * 10.0) * 0.2);
  out_color += (smoothstep(0.1 + tt, 0.2 + tt, uv0.x) - smoothstep(0.3 + tt, 0.4 + tt, uv0.x)) * vec4(0.0, 0.5, 1.0, 1.0);
  out_color -= (smoothstep(0.1 + tt * 2.0, 0.2 + tt * 2.0, uv0.x) - smoothstep(0.3 + tt * 2.0, 0.4 + tt * 2.0, uv0.x)) * vec4(0.0, 0.5, 0.5, 1.0);

  //out_color = f * 0.5 + pow(t, vec4(5.1));
  float rad = dot(xy - 0.5, xy - 0.5);
  out_color *= pow(rad, 0.5);
  float rad2 = rad + sin(fGlobalTime * uv0.x) * 0.2;
  out_color += smoothstep(0.04, 0.02, rad2) * 0.2;
}
