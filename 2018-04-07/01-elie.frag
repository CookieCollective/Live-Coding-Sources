precision mediump float;

uniform float time;
uniform vec2 resolution;
uniform sampler2D camera;
uniform sampler2D key;
uniform sampler2D samples;
uniform sampler2D spetrum;

mat2 rot(float a)
{
  float c = cos(a), s = sin(a);
  return mat2(c, s, -s, c);
}

vec3 circle(vec2 uv, vec2 pos,float r, float s){
vec3 res = vec3 (smoothstep(r,r+s,length(uv-pos)));
return res;
}

void main () {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uv0 = uv;

    uv.x += sin(uv.y) / uv.y * exp(sin(time * 0.3)) * 0.5;
    uv.y += sin(uv.x) / uv.x * 0.1;

    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    float a = atan(uv.y, uv.x),
      d = length(uv);
    a=a/6.2831+.5;
    d-=time*.1;

    float a0 = a + fract(d);
    float r1 = sin(time) + sin(a * 31.4);
    float r2 = sin(time + 3.14) + sin(a0 * 31.4 + 1.51 * pow(sin(time + a0 * 32.), 2.));
    float r3 = sin(time + 3.14) + sin(-a0 * 31.4 + 1.51 * pow(sin(-time - a0 * 32.), 2.));
    vec3 c1 = circle (uv0.xy, vec2(0.5,0.5),r1,0.35);
    vec3 c2 = circle (uv0.xy, vec2(0.5,0.5),r2,0.5);
    vec3 c3 = circle (uv0.xy, vec2(0.5,0.5),r3,0.5);
    c1-=c2;

    vec3 color = texture2D(camera, vec2(a, fract(d))).rgb;
    vec3 color2 = texture2D(camera, vec2(a, fract(d)) * 2.).rgb;

    //color -= color2 * 0.5;

    color.x*=1./(c1.x);
    color.y *= 1./c2.x;
    color.b *= c3.r;

    //color -= color2 * 2.;

    gl_FragColor = vec4(color,1.);
}
