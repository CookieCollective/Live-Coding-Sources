#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime
#define repeat(p,r) (mod(p,r)-r/2.)

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
vec3 lookat (vec3 eye, vec3 at, vec2 uv, float fov) {
  vec3 forward = normalize(at-eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward * fov + right * uv.x + up * uv.y);
}

float map (vec3 pos) {
  
  vec3 p0 = pos;
  float cell = 6.;
  float iz = floor(pos.z/cell);
  //pos.z = repeat(pos.z + time, cell);
  //pos.xz *= rot(time);
  //pos.xy *= rot(time);
  float scene = 1.0;
  float range = 2.0;// + 1.0 * sin(time);
  float a = 1.0;
  float falloff = 1.2;
  const float count = 7.;
  for (float index = count; index > 0.; --index) {
    pos.xz *= rot(time*.05/a);
    //pos.yz *= rot(sin(time)*0.2);
    pos = abs(pos)-range*a;
    //scene = min(scene, length(pos)-0.5*a);
    scene = min(scene, max(pos.x,max(pos.y,pos.z)));
    a /= falloff;
  }
  scene = max(-scene,0.);
  //pos = repeat(pos, .1);
  //scene = max(scene, -length(pos.xy)+.05);
  //scene = max(scene, -length(p0.xy)+1.0);
  
  pos = p0;
  //pos.z = repeat(pos.z + time, cell);
  a = 1.0;
  float shape = 1.;
  for (float index = 4.; index > 0.; --index) {
    pos.xz *= rot(time*.2);
    pos.yz *= rot(time*2.);
    pos.xz = abs(pos.xz)-.3*a;
    shape = min(shape, length(pos.xy)-0.2*a);
    a /= falloff;
  }
  //shape = max(shape, length(p0)-.5);
  //scene = min(scene, shape);
  
  //scene = max(scene, length(p0)-2.);
  return scene;
}

vec3 getNormal (vec3 p) {
  vec2 e = vec2(0.001,0);
  return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0,0.,-2);
  vec3 ray = lookat(eye, vec3(0.,sin(time*.2)*.5,0), uv, .5);
  float total = 0.0;
  float shade = 0.0;
  const float count = 100.;
  for (float index = count; index > 0.; --index) {
    float dist = map(eye+ray*total);
    if (dist < 0.001) {
      shade = index/count;
      break;
    }
    dist *= .9;
    total += dist;
  }
  vec3 color = vec3(shade);
  vec3 normal = getNormal(eye+ray*total);
  color = vec3(.3)*clamp(dot(normal, normalize(vec3(0,1,-1))),0.,1.);
  color += vec3(.9)*pow(clamp(dot(normal, -ray),0.,1.), 8.);
  color *= shade;
  out_color = vec4(color,1);
}