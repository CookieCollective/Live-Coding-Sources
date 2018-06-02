/*
"pixelRatio" : 1
*/

precision mediump float;
uniform float time;
uniform vec2 resolution;

vec2 scene(vec4 p) {
  return vec2(length(p.xyz) - 1.5, 1.0);
}

vec4 shade(vec3 p, float mat) {
  return vec4(mat);
}

vec4 march(vec3 o, vec3 d) {
  vec2 s;
  int i = 0;
  for ( ; i < 100 ; ++i) {
    s = scene(vec4(o, time));
    if (s.x < 0.01) {
      break;
    }
    o += s.x * 0.9 * d;
    s.y = 0.0;
  }

  return vec4(1.0);
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution -.5;
  uv.x *= resolution.x / resolution.y;

  vec3 d = normalize(vec3(uv, -1.0));
  vec3 o = vec3(0.0, -1., 0.);

uv.x = mod(uv.x + uv.y * pow(cos(time) * cos(time), 4.), (0.2+ 0.3 * pow(sin(time), 4.)))-0.5*(0.2+0.3*pow(sin(time), 4.));

uv.xy += sin(uv.x * 10. + pow(cos(time * 2.), 4.0)) + (pow(cos(time*.1), 5.) + sin(time*.1)) * 1.0;
uv.x += exp(uv.y*0.1);
  vec4 c = vec4(sin(uv.x * 10. + time) * pow(sin(uv.y * 10. + time), 4.));
  c = c + vec4(1.0, 2.0, 0.5, 1.0) * cos(time) * exp(cos(time * 2.0));
  //c += marsch(o, d);
  // c += vec4(1.0, 0.5, 0.0)
  gl_FragColor = c;
}
