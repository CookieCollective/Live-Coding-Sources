precision mediump float;
uniform float time;
uniform vec2 resolution;

mat2 rot(float a) {
  float c=cos(a), s=sin(a);
  return mat2(c, s, -s, c);
}

float xor(float a, float b) {
  return (min(a + b, 1.) - a * b);
}

#define palette(a,b,c,d,t) (a+b*cos(6.283*(c*t+d)))

void main() {
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv -= .5;
  uv.x *= resolution.x / resolution.y;

  float t = mod(time, 64.) / 8.;
  uv *= rot((floor(t) + smoothstep(.95, 1., fract(t))) * 6.283 / 8.);
  float mask = step(1., mod(uv.x*8. + time, 2.));
  mask = xor(mask, step(1., mod(uv.y*8. + sin(time) * .2, 2.)));

  vec3 color = palette(vec3(.5), vec3(.5), vec3(1.), vec3(0,1,2)/3., time + uv.x*2. + sin(uv.y*4.));

  gl_FragColor = vec4(mask*color, 1.0);
}
