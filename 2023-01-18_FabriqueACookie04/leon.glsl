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
#define repeat(p,r) (mod(p,r)-r/2.)

float gyroid (vec3 p) { return dot(sin(p), cos(p.yzx)); }

mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float random (vec2 s) { return fract(sin(dot(s,vec2(1321.1241,125.2134))*74.57)); }

vec3 cam;
float rng;

float noise (vec3 p)
{
   float result = 0., a =.5;
  for (float i = 0.; i < 3.; ++i)
  {
    result += abs(gyroid(p/a))*a;
    a /= 2.;
  }
  return result;
}

    float map(vec3 p)
    {
      float dist = 100.;
      vec3 q = p;
      
      float grid = 1.5;
      //p.z -= time * .1;
      //p = repeat(p+grid/2., grid);
      float t = time*1.1;// + q.z;
      t += rng*.1;
      p.xz *= rot(t);
      p.yz *= rot(t);
      t = pow(fract(t), 0.4) + floor(t);
      float a = 1.;
      float r = .4+.2*sin(time*1.-length(p)*3.0);
      const float count = 5.;
      for (float i = 0.; i < count; ++i)
      {
        p.xy *= rot(t/a);
        p.xz *= rot(t/a);
        p.xz = abs(p.xz)-r*a;
        dist = min(dist, length(p)-.05*a);
        a /= 1.8;
      }
      
      //dist -= noise(q*3.)*.1;
      dist = max(abs(dist)-.01, -(length(q-cam)-.5));
      
        
      return dist;
    }

    void main(void)
    { 
      vec2 uv = gl_FragCoord.xy / v2Resolution.xy;
      vec2 p = (2.*gl_FragCoord.xy-v2Resolution.xy)/v2Resolution.y;
      cam = vec3(0,0,2);
      vec3 pos = cam;
      vec3 ray = normalize(vec3(p, -4.));
      rng = random(uv);
      
      const float count = 30.;
      float total = 0.;
      float shade = 0.;
      for (float i = count; i > 0.; --i)
      {
        float dist = map(pos);
        if (dist < .001 || total > 20.)
        {
          shade = i/count;
          break;
        }
        total += dist;
        pos += ray * dist;
      }
      vec3 color = vec3(0);
      if (total < 20.)
      {
        color = vec3(1);
        color = .5+.5*cos(vec3(1,2,3)*5.5+length(pos)+shade*8.);
        color *= 2.;
        color *= shade;
      }
      
      out_color = vec4(color, 1);
    }