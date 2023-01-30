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
/*
              vec4 plas( vec2 v, float time )
              {
                float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
                return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
              }
              */
              #define circle(u,s) (length(u)-s)
              #define sm(t,v) smoothstep(t, t*1.05, v)
              
              #define hash21(x) fract(sin(dot(x,vec2(145.2, 210.8)))-164.5)
              #define PI acos(-1.)
              #define time fGlobalTime
              
              void mo (inout vec2 p, vec2 d)
              {
                p = abs(p)-d;
                if (p.y>p.x) p=p.yx;
                }
              
              float truchet (vec2 uv)
              {
                 vec2 id = floor(uv);
                if(hash21(id)<.5) uv.x *=-1.;
                uv = fract(uv)-.5;
                
                float a = atan(uv.y,uv.x);
                a = cos(a*2.+time);
                float s = uv.x>-uv.y ? 1.:-1.;
                
                uv -= .5*s;
                //return sm(0.1, abs(circle(uv, 0.5)) );
                return abs(circle(uv, 0.5)) ;
              }
              
              float extrude (vec3 p, float d, float h)
              {
                vec2 q = vec2(d, abs(p.z)-h);
                return min(0., max(q.x,q.y))+length(max(q,0.));
                }
              
              float SDF (vec3 p)
              {
                p.z += time;
                float per = 5.;
                  p.z = mod(p.z, per)-per*.5;
                return extrude(p, truchet(p.xy),0.1)-0.3;
                }
              
              
              void main(void)
              {
                vec2 uv = vec2(2.*gl_FragCoord.xy-v2Resolution.xy)/ v2Resolution.y;
                uv *= 5.;
                mo(uv,vec2(0.5));
                vec3 ro = vec3(0.001,0.001,-2.), rd=normalize(vec3(uv,1.)),p=ro, col=vec3(truchet(uv));
                
                bool hit = false; float shad;
                for (float i=0.; i<64.; i++)
                {
                  float d = SDF(p);
                  if(d<0.001)
                  {
                    hit=true; shad = i/64.; break;
                    }
                    p += d*rd;
                  }
                  
                if (hit)
                {
                  col = vec3(1.-shad*3.);
                  }                  
                float t = length(p-ro);
                //vec3 col = vec3(t);
                
                  col = mix(col, vec3(0.8,0.,0.1), 1.-exp(-0.01*t*t));
                  
                float mask = texture(texFFTSmoothed, abs((uv.x-uv.y)*0.5)-0.25).x*1000.;
                
                if (mask>.5) col = vec3(0.8, 0.05, 0.1);
                out_color = vec4(sqrt(col), 1.);;
              }