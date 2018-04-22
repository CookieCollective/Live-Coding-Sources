
precision mediump float;

uniform float time;
uniform vec2 resolution;

mat2 rot (float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2 (c,s,-s,c);
}

vec2 moda (vec2 p, float per)
{
  float a = atan(p.y,p.x);
  float l = length(p);
  a = mod(a-per/2., per)-per/2.;
  return vec2(cos(a),sin(a))*l;
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
  return a+b*cos(2.*3.141592*(t+d));
}

float cylY (vec3 p, float r)
{
    return length(p.yz)-r;
}

float stars (vec3 p)
{
  float per = 0.5;
    p.xy = moda(p.xy, 2.*3.141592/5.);
    p.xy *= rot(time);
    p.xy = mod(p.xy-per/2.,per)-per/2.;
    return cylY(p,-p.x);
}

float sdSphere (vec3 p, float r) { return length(p) - r; }

float map (vec3 p)
{
  return stars(p);
}


void main () {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 ray = normalize(vec3(uv,1.));
  vec3 pos = vec3(0.001,0.001,-3.);
  float shade = 1.;
  for (float i = 0.; i <= 60.; i ++) {
    float dist = map(pos);
    if (dist < .001) {
      shade = i/60.;
      break;
    }
    pos += dist * ray;
  }
  vec3 pal = palette(length(pos.z),
  vec3(0.5),
  vec3(0.5),
  vec3(3.),
  vec3(0.0,0.1,time));

  vec3 color = vec3(1.-shade)*pal;
  gl_FragColor = vec4(color, 1);
}
