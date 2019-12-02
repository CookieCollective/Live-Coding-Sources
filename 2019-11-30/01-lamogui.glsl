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

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
float t = 0.0;

mat3 rot(vec3 v, float a){
  float c = cos(a);
  float s = sin(a);
  float _c = 1.0 - c;
  return mat3( c + _c * v.x * v.x, _c * v.x * v.y + s * _c * v.z, _c * v.x * v.z - s *v.y,
  _c * v.x * v.y - s * v.z, c +_c * v.y * v.y, _c * v.x * v.z + s * v.y,
_c * v.x * v.z + s * v.y, _c * v.y * v.z - s * v.x, c + _c * v.z *v.z  );
}


float coscoscos(vec3 p )
{
  vec3 g = rot(vec3(0.0,.0,1.0), p.z * 0.1) * p;
  return cos(g.x) + cos(g.y) + cos(g.z);
}


float grass( vec3 p ){
  float id = textureLod(texNoise, floor(p.xz)/512.0, 0).r;
  p.xz = mod(p.xz, 3.0) - 1.5;
  
  float h= p.y;
  p = rot(vec3(0.,1.,0.),60. * id + 360.0 * fract(texture(texFFTIntegrated, 0.1).x * 0.01)) * p;
  p = rot(vec3(1.,.0,.0), p.y * 0.2) * p;
  return length(p.xz) - id + pow(h * 0.2, 4.0);  
  
}

float map(vec3 p) {
  float d = 1000000.0;
  
  d = min(d, p.y);
  
  d = min(d,coscoscos(p)); 
  float gs = 80.0;
  vec3 pg = p * gs;
  d = min(d, grass(pg) / gs);
  d = min(d, grass(pg + vec3( 5.15856418916, 0.0, 7.4781)) / gs);
  d = min(d, grass(pg - vec3( 3.018, 0.0, 2.0015)) / gs);
  
  return d;
}
vec3 grad( vec3 p ){
  vec2 e =vec2(0.01, 0.0);
  float d = map(p);
  return normalize(vec3(d-map(p+e.xyy), d -map(p+e.yxy), d - map(p +e.yyx) ));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
float t = texture(texFFTIntegrated, 0.3).r;
  vec3 ro = vec3(0.0,0.2,fGlobalTime * 0.3);
  vec3 rd = normalize(vec3(uv, 0.7 - length(uv)));
  float st = 1.0;
  vec3 p = ro;
  for (float i = 0.0; i < 256.0; ++i){
    float d = map(p);
    if ( abs (d) < 0.001) {
      st = i/256.0;
      break;
    }
    p += rd * 2.0 *d * i / 256.0;
}
  vec3 color = mix(vec3(0.4,1.0,0.6) * st, vec3(1.0), 0.01 * distance(ro, p)) ;

if ( abs(coscoscos(p)) < 0.1) {

  float st2 = 1.0;
vec3 n = grad(p);
vec3 rd2 = reflect(rd, n);
vec3 ro2 = p + rd2 * 0.1;
  vec3 p2 = ro2;
  for (float i = 0.0; i < 256.0; ++i){
    float d = map(p2);
    if ( abs (d) < 0.001) {
      st = i/256.0;
      break;
    }
    p2 += rd2 * 2.0 *d * i / 256.0;
}
color += mix(vec3(0.4,1.0,0.6) * st, vec3(1.0), 0.01 * distance(ro, p2));
}

//color = pow(color, vec3(1.0/1.8));
  out_color = vec4(color, 1.0);
}