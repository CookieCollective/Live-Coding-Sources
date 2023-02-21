/*{
  "osc": 4000,
  "glslify": true,
  "pixelRatio": 1
}*/


#pragma glslify: import('./common.glsl')


void main() {
    vec2 uv = (gl_FragCoord.xy-resolution/2.) / resolution.y;
    vec3 color = vec3(0.);
    gl_FragColor = vec4(color, 1);
}
