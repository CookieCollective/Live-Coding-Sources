precision highp float;

uniform float time;
uniform vec2 resolution;

// Thanks Inigo :)
float sdSegment(vec2 p, vec2 a, vec2 b)
{
  vec2 pa = p-a, ba = b-a;
  float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1.);
  return length(pa-ba*h);
}
#define sat(a) clamp(a, 0., 1.)


vec3 drawTheBlobs(vec2 uv, vec3 col, vec3 rgb)
{
  vec3 color = col;
  float an2 = atan(uv.y, uv.x);
  float rep2 = acos(-1.)*2./9.;
  float id = floor((an2+rep2*.5)/rep2);
  float sector2 = mod(an2+rep2*.5,rep2)-rep2*.5;
  uv = vec2(sin(sector2), cos(sector2))*length(uv);
  uv.x += sin(uv.y*10.+time*3.+id)*.02;
  uv.y -= (sin(id+time)*.5+.5)*.2;
  float blob = sdSegment(uv, vec2(0.,20.), vec2(0.,.2))-.05;
  color = mix(color, rgb, 1.-sat(blob*500.));
  uv.x = abs(uv.x);
  float blink = sat(sin(time*5.)+sin(time*3.+id)+sin(time*2.+id));
  float eyes = length((uv-vec2(0.02,0.2))*vec2(1.,1.+blink*5.))-.01;
  vec3 eyeCol = mix(vec3(1.,1.,0.2), vec3(.8,.5,.7), sin(id)*.5+.5);
  color = mix(color, eyeCol, 1.-sat(eyes*500.));

    return color;
}
mat2 r2d(float a) { float c = cos(a), s =sin(a); return mat2(c, -s, s, c);}
vec3 rdr(vec2 uv)
{
  vec3 color = vec3(0.);
  for (float i = 16.; i > 0.; --i)
  {
    float f = i/16.;
    vec3 base = vec3(.3,.1,.05);
    base.xy *= r2d(time*.05+uv.x);
    base = abs(base);
    vec3 rgb = mix(vec3(0.),base,f);
    color = drawTheBlobs(uv*(1.+f*8.)*r2d(i+time*.1+f), color, rgb);
  }
  color = drawTheBlobs(uv, color, vec3(0.));

return color;
}
vec3 rdr2(vec2 uv)
{
  vec2 dir = normalize(vec2(1.))*.01;
  vec3 col = vec3(0.);
  col.x = rdr(uv+dir).x;
  col.y = rdr(uv).y;
  col.z = rdr(uv-dir).z;
  return col;
}

void main() {
    vec2 uv = (gl_FragCoord.xy-resolution/2.) / resolution.y;
    vec2 saveuv = uv;
    float rep = acos(-1.)*2./mix(1.,8.,sat(sin(time*.25)*.5+.5));
    uv = abs(uv);
    float an = atan(uv.y, uv.x);
    float sector = mod(an+rep*.5,rep)-rep*.5;
    uv = vec2(sin(sector), cos(sector))*length(uv);

    float shape = abs(uv.x)-.05;
    vec3 color = vec3(0.);
    color = mix(color, vec3(1.,0.,0.)*color, 1.-sat(shape*500.));
color = vec3(.1,.2,.3)*.5*(1.-sat(length(uv)));
    uv = saveuv;
    uv *= 1.-sat(length(uv*.75));
    color = rdr2(uv);
    float lenny = abs(uv.x)+abs(uv.y);
    color += 5.*vec3(.5,.1,.1)*pow(1.-sat(lenny*2.),2.);
    gl_FragColor = vec4(color, 1);
}
