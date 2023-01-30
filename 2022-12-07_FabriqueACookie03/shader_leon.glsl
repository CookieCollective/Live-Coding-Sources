/*{ "camera": true, "audio": true }*/
uniform sampler2D camera;
uniform sampler2D backbuffer;

precision highp float;

uniform float time, volume;
uniform vec2 resolution;
uniform sampler2D spectrum;
uniform sampler2D midi;
float rng;
mat2 rot(float a){
  float c=cos(a),s=sin(a); return mat2(c,s,-s,c);
}
#define repeat(p,r) (mod(p,r)-r/2.)
float map (vec3 p)
{
  vec3 q = p;
  float dist = 100.;
  //p.z = repeat(p.z - time * .2, 2.);
  float t = time*2. - p.z*.5;;
  t = pow(fract(t), 10.) + floor(t);
  t += sin(time*2.)*.1;
  //t += q.z;
  //t += rng*.1;
  //t = 104.;
  float tt = time * 1.;
  tt = pow(fract(tt), 10.) + floor(tt);
  float r = .0+.8*abs(sin(tt*2.+p.z*2.1));
  //r = .5 + volume;
  //r += rng * .1;
  p.xy *= rot(time);
  p.xz *= rot(time);
  float a = 1.;
  const float count = 8.;
  for (float i = 0.; i < count; i++)
  {
     p.xz *= rot((t)*.4);
      p.yz *= rot((t*4.)*.4);
    p.x = abs(p.x)-r*a;
    dist = min(dist, length(p)-.3*a);
    a /= 1.2;
  }
  //dist = max(abs(dist), -length(q)+0.8);
    return dist*.3;
}

void main() {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.xx;
    vec2 ouv = gl_FragCoord.xy/resolution.xy;
    vec3 pos = vec3(0,0,3);
    vec3 ray = normalize(vec3(uv, -0.4));
    rng = fract(sin(dot(uv, vec2(132.5,534.42124)))*12432.4214);
    float shade = 0.;
    const float count = 100.;
    for (float i = count; i > 0.; --i) {
      float dist = map(pos);
      if (dist < 0.001) {
        shade = i/count;
        break;
      }
      pos += ray * dist;
    }
    vec3 col = vec3(1);
    col = .95+.5*cos(vec3(1,2,3)*4.5+floor(pos.z*2.) + time + shade * 2.);
    col *= shade*shade*shade;
    gl_FragColor = vec4(col, 1.0);
}
