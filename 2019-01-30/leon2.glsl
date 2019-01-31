#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime
#define repeat(p,r) (mod(p,r)-r/2.)

mat2 rot(float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }

vec3 look (vec3 eye, vec3 at, vec2 uv) {
  vec3 front = normalize(at-eye);
  vec3 right = normalize(cross(front, vec3(0,1,0)));
  vec3 up = normalize(cross(front, right));
float fov =  (1.+.5*sin(time*8.));
  return normalize(front * .3 + right * uv.x + up * uv.y);
  }

float map (vec3 pos) {
  float scene = 10.;
pos.z -= time * 10.;
pos = repeat(pos, 5.);
   
  const float count = 3.;
vec3 p = pos;
  for (float i = count; i > 0.; --i) {
    float r = i / count;
    p = abs(p)-(.5+.3*sin(time*8.))*r;
  p.xz *= rot(time*.2);
  p.yz *= rot(time*.1);
float rr = .2+.1*sin(time* 8.);
rr *= r;
  if (sin(time)<.0) {
    scene = min(scene, length(p)-rr);
    } else {
scene = min(scene, length(p.xz)-rr*.2);
  scene = min(scene, length(p.yz)-rr*.2);
  scene = min(scene, length(p.xy)-rr*.2);
}
}

  //scene = min(scene, max(0., (length(pos.xz)-1.)));

  pos.xz *= rot(pos.y + time *4.0+ sin(time*4.+pos.y));
  pos.x += 1.;

  pos.xz *= abs(pos.xz)-.5;
  pos.xz *= abs(pos.xz)-.5;  
//scene = min(scene, length(pos.xz)-.02);
  return scene;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
vec2 p = uv;
  uv /= 1.-length(uv)*4.;
  vec3 eye = vec3(0,0,-3);
  eye.xz *= rot(time*.8);
  eye.yz *= rot(time * .5);
  vec3 ray = look(eye, vec3(0), uv);
  vec3 pos = eye;
  float shade = 0.;
  const float count = 50.;
  for (float i = count; i > 0.; --i) {
    float dist = map(pos);
    if (dist < .001) {
      shade = i / count;
      break;
    }
    pos += ray * dist;
  }
vec3 color = vec3(.5)+vec3(1.)*cos(vec3(.01,.011,.0123)*time*5.+shade*2.+length(pos)*2.);
    float funk = step(.0, sin(-time*4.+length(uv)*4.+atan(uv.y,uv.x)));
  color = mix(color, 1.-color, funk);

  p.y-=sqrt(abs(p.x))*.5*(1.+.2*sin(time*4.));
  float heart = step(.0, length(p)-.2);
out_color = vec4(color*shade, 1.);
out_color.r += 1.-heart;
}