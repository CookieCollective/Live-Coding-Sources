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
              
              float fft;

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
              #define repeat(p,r) (mod(p,r)-r*.5)
              #define hash21(x) fract(sin(dot(x,vec2(145.2, 210.8)))-164.5)
              #define PI acos(-1.)
              float time  = mod(fGlobalTime*.3, 300.);
              
              mat2 rot(float a) {
                float ca=cos(a);
                float sa=sin(a);
                return mat2(ca,sa,-sa,ca);
              }
              
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
                
                
               float rnd(float t) {
                 return fract(sin(t*532.524)*714.521);
               }
               float curve(float t, float d) {
                 t/=d;
                 return mix(rnd(floor(t)),rnd(floor(t+1)), pow(smoothstep(0,1,fract(t)),10.));
               }
               
               float box(vec3 p, vec3 s) {
                 p=abs(p)-s;
                 return max(p.x, max(p.y,p.z));
                 
               }
              
              float SDF (vec3 p)
              {
                vec3 p2=p;//+vec3(0,0,0.7);
                vec3 p3=p;
                p.z += time;
                float per = 5.;
                  p.z = mod(p.z, per)-per*.5;
                 float d= extrude(p, truchet(p.xy),0.1)-0.3;
                
                d=10000;
                p2.z += time;
                
                float pz = p2.z;
                
                p2 = repeat(p2, 2.);
                
                p2.xz *= rot(time);
                p2.yz *= rot(0.7*time);
                p2=abs(p2);
                float a = 1.;
                float t = time * .1 + pz * 0.5 + fft * 5.;
                for(int i=0; i<5;i++) {
                  p2.xz *= rot(t*.8 + curve(time, 2.7)*4);
                  p2.yz *= rot(t*.7/a);
                  p2.xz=abs(p2.xz)-.8*a;
                  //p2.x-=0.6+curve(time, .7)*.01;
                  d = min(d, length(p2)-.1*a-fft*50.);
                  a /= 1.8;
                  //d=min(d, box(p2, vec3(0.3)));
                 
                  }
                 //d=min(d, length(p2.xz)-.1); 
                 //d=max(d, -p3.z-2.5+length(p3)*.3);
                //d+=max(0,length(p3)-2.);
                  d = max(abs(d)-.001, -(length(p.xy)-.5));
                return d;
                }
              
              
              void main(void)
              {
                vec2 uv = vec2(2.*gl_FragCoord.xy-v2Resolution.xy)/ v2Resolution.y;
                //uv *= 5.;
                vec2 uv2=uv;
                //uv *= .5+curve(time, .3);
               // uv *= rot(time*.3-sin(length(uv)-time*5.)*.1);
                
                for(int i=0;i<3; ++i) {
                  //uv.x=abs(uv.x);
                  //uv *= rot(curve(time, .2)+time*.3+i);
                }
           fft = texture(texFFTSmoothed, 0.).r;
                
                //mo(uv,vec2(0.5));
                vec3 ro = vec3(0.001,0.001,-2.), rd=normalize(vec3(uv,1.)),p=ro, col=vec3(0);
                rd.xy *= rot(time);
                rd.yz *= rot(time);
                bool hit = false; float shad;
                float d=0;
                for (float i=0.; i<64.; i++)
                {
                  d = SDF(p);
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
                
                  //col = mix(col, vec3(0.8,0.,0.1), 1.-exp(-0.01*t*t));
                 //col.xz *= rot(t*.3); 
                
                  if(length(uv2)>-5+texture(texFFTSmoothed, 0.01).x*400.) {

                  
                float mask = texture(texFFTSmoothed, abs((uv.x-uv.y)*0.5)-0.25).x*1000.;
                    
                //if (mask>.5) col = vec3(0.8, 0.05, 0.1);
                                    
                    float t2=time*.2 + uv.x*.05 + length(p)*.1 + rnd(floor(abs(uv2.x)*1.-time));
                  //col.xz *= rot(t2);
                  //col.yz *= rot(-t2*.7);
                  col=abs(col);
                    col = .5+.5*cos(vec3(1,2,3)*5.+floor(p.z*4.)*.1+time*10.);
                    col *= shad;
                    
                  }
                out_color = vec4(sqrt(col), 1.);;
              }