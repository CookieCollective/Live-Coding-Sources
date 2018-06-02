/*{
"pixelRatio" : 3,
"PASSES" : [{"TARGET": "buf", "fs": "theotime.frag"}, {}]
}*/

precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform sampler2D buf;

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution;
  //gl_FragColor = texture2D(buf, uv);
  float c = cos(time*10.)*.009;
  float t = tan(time)*.002;

  gl_FragColor.r = texture2D(buf, uv+vec2(-c, c)).r;
  gl_FragColor.g = texture2D(buf, uv+vec2(-t, t)).g;
  gl_FragColor.b = texture2D(buf, uv+vec2(c, -c)).b;
}
