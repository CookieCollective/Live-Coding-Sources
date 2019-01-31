#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

#define iTime fGlobalTime
#define SPEED 3.

vec3 palette(float x) {
  float wave = sin(2. * iTime) * 0.5 + 0.5;
  vec3 a = vec3(1);
  vec3 b = vec3(wave);
  vec3 c = vec3(.5,.5, wave);
  vec3 d = vec3(.3, .6, 1);
  return a + b * cos(c + d * x);
}

mat2 rot2d(float a) {
  float c = cos(a);
  float s = sin(a);

  return mat2(c, s, -s, c);
}

float GetDistSphere(vec3 p, vec4 sphere) {
  return length(p - sphere.xyz) - sphere.w;
}

float GetDistSphereRep(vec3 p, vec4 sphere, vec3 rep) {
  vec3 q = mod(p, rep) - 0.5 * rep;
  return GetDistSphere(q, sphere);
}

float GetDist(vec3 p) {
//  p.xy *= rot2d((iTime / 100.) * p.z / 50.);
//  p.xy *= rot2d(p.x * p.y) ;
  p.xy *= rot2d(p.x) ;
  vec4 sphere = vec4(0, 0, .5, .4);
//  float d = GetDistSphere(p, sphere);
  vec3 rep = vec3(3, 3, 2);
  float d = GetDistSphereRep(p, sphere, rep);
  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
  float d = 0.;

  for (int i = 0; i < 100; i++) {
    vec3 p = ro + d * rd;
    float dScene = GetDist(p);
    d += dScene;

    if (dScene < 0.01 || dScene > 100.) {
      break;
    }
  }

  return d;
}

vec3 GetNormal(vec3 p) {
  vec2 e = vec2(0.01, 0);

  vec3 n = GetDist(p) - vec3(
    GetDist(p - e.xyy),
    GetDist(p - e.yxy),
    GetDist(p - e.yyx)
  );

  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 light = vec3(0, 3, iTime * SPEED + 1);
  vec3 toLight = light - p;
  vec3 n = GetNormal(p);
  float dif = dot(n, normalize(toLight));

  return dif;
}

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv *= 2.;
  vec3 col = vec3(0.);
  
  vec3 ro = vec3(0, sin(iTime), iTime * SPEED);
  
  vec3 rd = normalize(vec3(uv.x, uv.y, 1));

  float d = RayMarch(ro, rd);
  vec3 p = ro + d * rd;
  float dif = GetLight(p);
  col = vec3(dif * palette(p.z / 100.));
//  col = n;
  out_color = vec4(col, 1.);
}

/*  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = texture( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  vec4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = clamp( t, 0.0, 1.0 );
  out_color = f + t;*/