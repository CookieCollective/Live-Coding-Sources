
#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime
float hash (vec2 seed) { return fract(sin(dot(seed*.1684,vec2(54.649,321.547)))*450315.); }

mat2 rot (float a) { float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
#define repeat(p, r) (mod(p,r)-r/2.)

float dither;
float material;
float glow;

float map(vec3 p)
{
  float dist = 1000.;
  float shape = 1000.;
  
  float cell = 12.;
  float idz = floor((p.z+time*.2)/cell);
  //p.z = repeat(p.z+time, cell);
  float cycle = 1.;
  float spawn = pow(sin(fract(time/cycle)*3.14), 10.);
  const int count = 6;
  float r = 1.3;
  float s = 0.1;
  float f = 1.8;
  float h = 0.2;
  float a = 1.0;
  float t = time*0.5+dither*0.05+p.x*.2;//+idz;
  for (int index = count; index > 0; --index)
  {
    p.xy *= rot(0.1*t/a);
    p.xz *= rot(sin(t/a)+t);
    p.yz *= rot(t+sin(t*4.));
    p.z = abs(p.z)-r*a;
    shape = max(length(p.xz)-s*a, abs(p.y)-h*a);
    material = shape < dist ? float(index) : material;
    dist = min(shape, dist);
    a /= f;
  }
  //dist = length(p)-s;
  dist = min(dist, length(p)-.05*spawn);
  
  return dist;
}

void main(void)
{
  float delay = 4.;
  vec2 uv = (gl_FragCoord.xy-0.5*v2Resolution.xy)/v2Resolution.y;
  
  //uv *= rot(time*0.1);
  dither = hash(uv+fract((time)));
  glow = 0.;
  vec3 color = vec3(0.);//*smoothstep(0.0, 2.0, length(uv));
  vec3 eye = vec3(0,0,-6);
  vec3 ray = normalize(vec3(uv, 2.));
  vec3 pos = eye + ray * (2.+dither*1.);
  const int steps = 40;
  for (int index = steps; index > 0; --index)
  {
    float dist = map(pos);
    if (dist < 0.001)
    {
      float shade = float(index)/float(steps);
      vec3 tint = vec3(0.25)+vec3(0.75)*cos(vec3(1,2,3)*.8+material*.1+1.+pos.z*2.+uv.y*1.+shade+floor(time/delay)*8.3);
      color = tint * shade;
      break;
    }
  
    if (material == floor(mod(time, 8.)))
    {
      float fade = fract(time);
       //glow += sin(fade*3.14)*clamp(0.01/max(0., dist),0.,1.);
    }
    pos += dist * ray;
  }
  
  color += vec3(1)*glow;
  
  vec2 splash = -uv * 20.*length(uv)/v2Resolution;
  vec3 frame = texture(texPreviousFrame, gl_FragCoord.xy/v2Resolution.xy+splash).rgb;
  
  color = max(color, frame);
  
  float reset = fract(time/delay);
  color *= smoothstep(1.0, 0.9, reset);
  
	out_color = vec4(color,1);
}

