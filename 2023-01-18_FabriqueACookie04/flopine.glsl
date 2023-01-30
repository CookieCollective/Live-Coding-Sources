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

          #define n(u) fract(sin(dot(vec2(232.1, 314.7),u))*167.5) 
          #define rot(a) mat2(cos(a),sin(a), -sin(a), cos(a))

          #define PI acos(-1.)
          #define TAU (2.*PI)
          
          
          float truchet(vec2 uv)
          {
            vec2 id = floor(uv);
            uv = fract(uv)-.5;
          
            if (n(id*.2)<.5) uv.x *= -1.;
            float s = (uv.x>-uv.y)?1.:-1.;
            
            uv -= s*.5;
            
            return abs(length(uv)-.5);
            return step(0.025, abs(length(uv)-.5));
          }

          float extrude (vec3 p, float d, float h)
          {
            vec2 q = vec2(d, abs(p.z)-h);
            return min(0.,max(q.x,q.y))+length(max(q, 0.));
            }
            
            float SDF (vec3 p)
            {
              float speed = 7.;
              p.z += floor(fGlobalTime*speed) + pow(fract(fGlobalTime*speed), .1)+n(p.xy)*.5;
              p.xy *= rot(p.z*.1);
              float per = 2.;
              float id = floor(p.z/per);
              p.xy *= (mod(id, 2.)<.5) ? rot(PI/4.) : rot(PI/2.);
              p.z = mod(p.z, per)-per*.5;
              float r = mix(0.001, 0.2, sin(length(p.xy)-fGlobalTime*2.));
              return extrude(p, truchet(p.xy), 0.1)-r;
              }

          void main(void)
          {
            vec2 uv = (2.*gl_FragCoord.xy - v2Resolution.xy)/ v2Resolution.y;
           // uv *= 2.;
            
            //uv = abs(uv)-.05;
            
            vec3 ro = vec3(0.01, 0.01, -4.),rd=normalize(vec3(uv, 1.)), p=ro,
            col=vec3(truchet(uv));            
            
            bool hit=false; float shad;
            for(float i=0.; i<64.; i++)
            {
              float d= SDF(p);
              if (d<0.01)
              {
                hit=true; shad = i/64.; break;
                }
                p += d*rd;
              }
              float t = length(p-ro);
            if (hit)
            {
              col = vec3(shad*.85); 
              }
              
              col = mix(col, vec3(.4, .7, .9), 1.-exp(0.005*t*t));
              
            out_color = vec4(sqrt(col), 1.);
            //out_color = texture(texFFT, abs(uv.x)+abs(uv.y)).xxxx*100.;
          }