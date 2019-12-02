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

vec3 repeat(vec3 v, float c) {
  return mod(v, c) - c / 2.0;
}

float putaindebass() {
  return texture(texFFTIntegrated, 0.1).r;
}

vec2 rotate2d(vec2 p, float a) {
  return mat2(
    sin(a), -cos(a),
    cos(a), -sin(a)
  ) * p;
}

float sphere(vec3 pos, float radius) {
  return length(pos) - radius;
}

float plane(vec3 pos) {
  return pos.y;
}

float map(vec3 pos) {
  //float scene = 10000.0;
  
  //scene = plane(pos);
  
  pos.xz = rotate2d(pos.xy, sin(pos.z * 0.005 + fGlobalTime * 0.5) * 0.5);
  //pos.xz = rotate2d(pos.xy, sin(pos.z * 0.01));
  
  pos = repeat(pos, 10.0);
  
  
  float scene = sphere(pos, 2.0);
  return scene;
}


void main(void)
{
  vec2 uv = gl_FragCoord.xy / v2Resolution;
  uv = uv * 2.0 - 1.0;
  uv.x *= v2Resolution.x / v2Resolution.y;
  
  vec3 ro = vec3(sin(fGlobalTime), sin(fGlobalTime * 0.1), putaindebass() * 50.0);
  vec3 pos = ro;
  vec3 dir = normalize(vec3(uv, 1.4));
  
  const float count = 256.0;
  
  vec3 color = vec3(0.0);
  
  for(float i = 0; i < count; i++) {
    float d = map(pos);
    
    if(d < 0.01) {
      color = vec3(1.0);
      
      color = 1.0 - vec3(i / count);
      
      break;
    }
    
    pos += d * dir;
  }
  
  float fog = length(pos - ro) * 0.0065;
  
  color *= 1.0 - fog;
    
  
  out_color = vec4(color, 1.0);
}