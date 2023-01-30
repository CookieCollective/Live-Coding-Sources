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
#define FFT(a) pow(sat(texture(texFFT, a).x*500.), .5)
          #define PI acos(-1.)
          #define TAU (2.*PI)
          #define sat(a) clamp(a, 0., 1.)
              float _seed;
              
              float hash(float seed)
              {
                return fract(sin(seed*123.456)*123.456);
              }
              float rand()
              {
                return hash(_seed++);
              }
          float _cucube(vec3 p, vec3 s, vec3 th)
               {
              vec3 l = abs(p)-s;
                 float c = max(l.x,max(l.y, l.z));
                 l = abs(l)-s*th;
                 float x = max(max(l.x, c),l.y);
                 float y = max(max(l.z, c),l.y);
                 float z = max(max(l.x, c),l.z);
                 return min(min(x, y), z);
                 }               
          
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

vec2 _min(vec2 a, vec2 b)
            {
              if (a.x < b.x)
                return a;
              return b;
            }
            
            vec2 SDF (vec3 p)
            {

                vec2 acc = vec2(1000., -1.);
              vec3 op =p; 
                p.z += fGlobalTime;
              vec3 pg = p*1.-vec3(0.,-fGlobalTime,0.);
              
                float gyr = dot(sin(pg.xyz), cos(pg.yzx))+1.2+FFT(.5);
          
                gyr = max(gyr, abs(p.x)-3.);
                float shape = max(gyr, (length(op)-10.));
                 acc = _min(acc, vec2(shape, 0.));
              
              
              float ground = -p.y+
              (sin(p.x+fGlobalTime)*.2+sin(p.z+fGlobalTime)*.2
              +sin(length(p.xz)+fGlobalTime)*.5)*.2;
              acc = _min(acc, vec2(ground, 1.));
              
float cucube=_cucube(op, vec3(5.), vec3(.1));
acc = _min(acc, vec2(cucube, 2.));              
              
              return acc;
              }
              
              vec3 getCam(vec3 rd, vec2 uv)
              {
                uv *= 1.-sat(length(uv)*.5);
                vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
                vec3 u = normalize(cross(rd, r));
                return normalize(rd+r*uv.x+u*uv.y);
              }
              vec3 accCol;
              vec3 trace(vec3 ro, vec3 rd, int steps)
              {
                accCol =vec3(0.);
                vec3 p=ro;
                for (int i = 0; i < steps && distance(p, ro) < 20.; ++i)
                {
                  vec2 res = SDF(p);
                  if (res.x < 0.01)
                    return vec3(res.x, distance(p,ro), res.y);
                  p+=res.x*rd;
                accCol += vec3(1., .3, .5)*(1.-sat(res.x/1.5))*.01;
                }
                return vec3(-1.);
              }
              vec3 getNorm(vec3 p, float d)
              {
                vec2 e=vec2(0.01,0.);
                return normalize(vec3(d)-vec3(SDF(p-e.xyy).x, SDF(p-e.yxy).x, SDF(p-e.yyx).x));
              }
              vec3 getmat(vec3 p)
              {
                  vec3 col;
                                col = vec3(.8, .4, .6); // Code pas indenté t"'as vu ?!
                col.xy *= rot(p.z*5.);
  return col;
              }
              
              // VOILA MOI C Z0RG !
              // Le code C COOL :)
              vec3 rdr(vec2 uv){
                          uv *= rot(fGlobalTime*.1);
            //uv = abs(uv)-.05;
            float t = fGlobalTime*.2;
            float d = 15.;
            vec3 ro = vec3(0.01+sin(t)*d, -2., cos(t)*d);
            ro.xy += (vec2(rand(), rand())-.5)*.2;
            vec3 ta = vec3(0.,-2.,0.);
            vec3 rd=normalize(ta-ro);
            
            rd = getCam(rd, uv);
            
            
            vec3 col=vec3(truchet(uv))*.0;            
            
                float depth = 100.;
            vec3 res = trace(ro, rd, 64);
            if (res.y > 0.)
            {
              vec3 p = ro+rd*res.y;
              vec3 norm = getNorm(p, res.x);
              depth = res.y;
              if (res.z == 0.)
              {
                col = getmat(p);
              }
              if (res.z == 1.)
              {
                vec3 refl = normalize(reflect(rd, norm));
                vec3 resrefl = trace(p+norm*0.01, refl, 64);
                if (resrefl.y > 0.)
                {
                  vec3 prefl = p+norm*0.01+refl*resrefl.y;
                    col += getmat(prefl).zxy;
                }

              }
            }
              col = mix(col, vec3(.9, .1, .1)*.2, 1.-sat(exp(0.2*depth)));
              col += accCol;
            
return col;
                }
              
          void main(void)
          {
            vec2 ouv = gl_FragCoord.xy/v2Resolution.xy;
            vec2 uv = (2.*gl_FragCoord.xy - v2Resolution.xy)/ v2Resolution.y;
  _seed = texture(texNoise, uv).x+fGlobalTime;
            // uv *= 2.;
            
            float stp = .05;
            if (abs(uv.x)> .5)
            uv = floor(uv/stp)*stp;
vec3 col = rdr(uv);
            vec2 off = (vec2(rand(), rand())-.5)*.05;
            col = sat(col);
            col = mix(col, texture(texPreviousFrame, ouv+off).xyz*1.5, .5);
//            col += rdr(uv+(vec2(rand(), rand())-.5)*.1);
            out_color = vec4(col, 1.);
            //out_color = texture(texFFT, abs(uv.x)+abs(uv.y)).xxxx*100.;
          }