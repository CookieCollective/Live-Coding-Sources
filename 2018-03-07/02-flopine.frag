
precision mediump float;

uniform float time;
uniform vec2 resolution;


mat2 rot (float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c,s,-s,c);
}

vec2 moda (vec2 p, float per)
{
  float a = atan(p.y,p.x);
  float l = length(p);
  a = mod(a-per/2.,per)-per/2.;
  return vec2(cos(a),sin(a))*l;
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
  return a+b*cos(2.*3.141592*(c*t+d));
}
float sdSphere (vec3 p, float r) { return length(p) - r; }

float box (vec3 p, vec3 c)
{
    return length(max(abs(p)-c,0.));
}

float prim (vec3 p)
{
  float c = box(p,vec3 (1.));
  float s = sdSphere(p, sin(time)*0.3+1.3);
  return max(-s,c);
}

float prim2 (vec3 p)
{
  float per = 1.2;
  p.y = mod(p.y-per/2.,per)-per/2.;
 return prim(p);
}

float tent (vec3 p) {
  p.xz *= rot(3.141592/2.);
  p.yz = moda(p.yz, 2.*3.141592/8.);
  p.x += sin(p.y+time);
  return prim2(p);
}

float map(vec3 p)
{
  p.xz *= rot(time);
  p.yz *= rot(time*0.5);
  p.xz = moda(p.xz, 2.*3.141592/5.);
  return tent(p);
}

void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 ray = normalize(vec3(uv*2.,1.));
  vec3 pos = vec3(0.001,0.001,-16.);
  float shade = 0.;
  for (float i = 0.; i <= 70.; i ++) {
    float dist = map(pos);
    if (dist < .001)
    {
      shade = i/60.;
      break;
    }
    pos += dist * ray*0.5;
  }

  vec3 pal = palette(length(pos),
    vec3(0.5),
    vec3(0.5),
    vec3(0.2),
    vec3(0.0,0.1,0.5));
  vec3 color = vec3(shade)*pal;
  gl_FragColor = vec4(pow(color,vec3(0.45)), 1);
}
