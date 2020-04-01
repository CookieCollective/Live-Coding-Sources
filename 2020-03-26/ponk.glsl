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

float sdCube (vec3 p, vec3 r) {
  vec3 b = abs(p)-r;
  return max(b.x,max(b.y,b.z));
}

mat2 rot (float a) { 
  float c=cos(a),s=sin(a);
  return mat2(c,-s,s,c);
}

#define time fGlobalTime

float map (vec3 p, inout float mat) {
  float scene = 1.0;
  const float count = 8.;
  float a = 1.0;
  float falloff = 2.5;
  float speed = 0.1;
  float t = time*speed;//floor(time*speed) + pow(fract(time*speed), 0.5);
  float w = sin(time - length(p)*.5);
  for (float index = count; index > 0.; --index) {
    float r = 4. + 2. * w;
    p.xz *= rot(t*2.2);
    p.yz *= rot(t*4.1);
    p.yx *= rot(t*2.3);
    p.x = abs(p.x)-r*a;
    
    //p.x += sin(abs(p.z));
    p.y += abs(sin(p.z*2.))*.2;
    scene = min(scene, sdCube(p, vec3(2.+.5*sin(abs(p.z*3.14)),0.01,1)));
    a /= falloff;
  }
  p = abs(p)-0.2;
  p.xz *= rot(- time);
  p.yz *= rot(- time);
  p.yx *= rot(- time*2.);
  
  float sphs = max(abs(p.y)-2., length(p.xz)-0.02);
  mat = step(sphs, scene);
  scene = min(scene, sphs);
  sphs = length(p)-0.2;
  mat += step(sphs, scene);
  scene = min(scene, sphs);
  return scene * .5;
}

vec3 getNormal (vec3 p) {
  vec2 e = vec2(0.001,0);
  float m = 0.;
  return normalize(vec3(map(p+e.xyy,m)-map(p-e.xyy,m),map(p+e.yxy,m)-map(p-e.yxy,m),map(p+e.yyx,m)-map(p-e.yyx,m)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0,0,-12);
  vec3 ray = normalize(vec3(uv,1.));
  float total = 0.0;
  float shade = 0.0;
  float mat = 0.0;
  const float count = 100.;
  for (float index = count; index > 0.; --index) {
    float dist = map(eye+ray*total, mat);
    if (dist < 0.001) {
      shade = index/count;
      break;
    }
    total += dist;
  }
  
  vec3 color = vec3(0);
  vec3 normal = getNormal(eye+ray*total);
  if (mat == 0.0) {
    color += .7*vec3(0.1,1.,.2) * clamp(dot(normal, -ray), 0., 1.);
    color += vec3(0.54,.2,.1) * clamp(dot(normal, vec3(0,-1,0))*.5+.5, 0., 1.);
  } else if (mat == 1.0) {
    color += vec3(1.0) * clamp(dot(normal, vec3(0,-1,0))*.5+.5, 0., 1.);
  } else if (mat == 2.0) {
    color += vec3(1.,.1,0.) * clamp(dot(normal, vec3(0,-1,0))*.5+.5, 0., 1.);
  }
  color *= pow(shade, .2);
    
  
  out_color = vec4(color,1);
}