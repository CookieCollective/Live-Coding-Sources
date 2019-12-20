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

float time=0;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define rep(v,s) (fract((v)/s-0.5)-0.5)*s

float box(vec2 p, vec2 s) {
  p=abs(p)-s;
  return length(max(vec2(0),p)) + min(0.0,max(p.x, p.y));
}

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return length(max(vec3(0),p)) + min(0.0,max(p.x, max(p.y,p.z)));
}

float sph(vec3 p, float r) {
  return length(p)-r;
}

float cyl(vec2 p, float r) {
  return length(p)-r;
}

float prog=0;
float voiture(vec3 p) {
  
  vec3 p2=p;
  vec3 p3=p;
  
  float d = box(p, vec3(1.5,2.5,4));
  
  p.y += 2.5;
  d = min(d, max(cyl(p.xy, 1.5), abs(p.z)-4));
  
  p.y = abs(p.y-1.5)-1.5;
  d = min(d, box(p, vec3(1.6,0.1,4.1)));
  
  p2.x = abs(p.x)-1.6;
  p2.z = rep(p.z, 1.6);
  p2.y += 1.4;
  d = max(d, -box(p2, vec3(0.2,0.7,0.7)));
  
  p3.z = abs(p3.z)-4;
  p3.y += 1;
  d = max(d, -box(p3, vec3(0.6,1.2,0.2)));
  
  
  return d;
}

float roues(vec3 p) {
  

  p.y -= 3;
  p.x = abs(p.x)-1.8;
  p.z = min(3+p.z,max(p.z-3,rep(p.z, 1.5)));
  float d = abs(cyl(p.yz, 0.65))-0.1;
  d = max(d, abs(p.x)-0.2);
  
  p.yz *= rot(time * 4);
  
  p.y=abs(p.y);
  p.z=-abs(p.z);
  p.yz *= rot(0.7);
  p.y=abs(p.y);
  p.z=-abs(p.z);
  p.yz *= rot(0.4);
  d = min(d, box(p, vec3(0.05,0.05,0.7)));

  
  return d;
}

float rails(vec3 p) {
  
  p.y += 0.2;
  p.x=abs(p.x)-1.6;
  float d=box(p.xy, vec2(0.1,0.2));
  
  p.z = rep(p.z, 1.5);
  d=min(d, box(p, vec3(2.0,0.1, 0.3)));
  
  return d;
}

vec3 chemin(vec3 p) {
  vec3 off=vec3(0);
  off.x += sin(p.z * 0.04)*10;
  off.x += sin(p.z * 0.023)*22;
  off.y += sin(p.z * 0.03)*10;
  return off;
}

// distance fonction
float voit = 0;
float sol=0;
float wat=0;
float map(vec3 p) {
  
  vec3 p3=p;
  
  p += chemin(p);
  
  float h = texture(texNoise, p.xz * 0.01).x;
  h *= 10 * clamp(abs(p.x)/20,0,1);;
  
  vec3 p2 = p;
  
  p.y += 4.2;
  float tt=time*0.5;
  float t2 = fract(tt);
  t2 = smoothstep(0,1,t2);
  t2 = smoothstep(0,1,t2);
  t2 = pow(t2, 10);
  p.z += (floor(tt) + t2) * 30 + time*3; 
  prog = p.z;
  p.z = rep(p.z, 9.5);
  
  
  
  
  voit=voiture(p);
  float d = voit;
  
  d=min(d, roues(p));
  
  d=min(d, rails(p2));
  
  sol=-p2.y - h + 0.3;
  d=min(d, sol);
  
  wat=-p3.y+5;
  d=min(d, wat);
  
  return d;
}

vec3 camera(vec2 uv, vec3 s, vec3 t, float fov) {
  
  vec3 cz=normalize(t-s);
  vec3 cx=normalize(cross(cz, vec3(0,1,0)));
  vec3 cy=normalize(cross(cx, cz));
  
  return normalize(uv.x*cx - uv.y*cy + fov*cz);
}

vec3 norm(vec3 p) {
  vec2 off = vec2(0.01,0.0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
}

float shadow(vec3 p, vec3 r) {
  float shad=1;
  for(int i=0; i<30; ++i) {
    float d=map(p);
    shad=min(shad, d*10.0);
    p+=d*r;
  }
  return clamp(shad,0,1);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  time=mod(fGlobalTime,300);
  
  // camera position
  vec3 s=vec3(0,0,-30);
  s.yz *= rot(0.5);
  s.xz *= rot(0.7+time*0.2);
  
  // camera target
  vec3 t=vec3(0,-7,10);
  t.xz *= rot(time*0.3);
  
  s.z += time * 8;
  t.z += time * 8;
  
  s -= chemin(s);
  t -= chemin(t);
  
  float fov = 0.5 + pow(smoothstep(-1,1,sin(time*10.0)),10)*0.2;
  vec3 r = camera(uv, s, t, fov);
    
  vec3 p=s;
  float at=0;
  float dd=0;
  for(int i=0; i<100; ++i) {
    float d=map(p) * 0.7;
    if(d<0.001) {
      if(wat>0.01) {
        break;
      }
      d = 0.1;
      r.y = -r.y;
      r.x += (texture(texNoise, p.xz*0.03 + time*0.3).x-0.4)*0.5;
      r=normalize(r);
    }
    if(dd>200) {
      break;
    }
    
    p+=r*d;
    dd+=d;
    at += 0.1/(0.1+abs(d));
  }
    
  float issol=step(sol,0.01);
  float isvoit=step(voit,0.01);
  float iswat=step(wat,0.01);
  float pp=floor(prog/9.5-0.5);
  vec3 n=norm(p);
  
  float fog = 1-clamp(dd/200,0,1);
  
  vec3 col=vec3(0);
    
  //col += at * 0.03 * vec3(1,0.5,0.3);
  
  vec3 l=normalize(-vec3(1,2,3));
  
  float shad=shadow(p + n * 0.2, l);
  
  float ao = clamp(map(p+n*0.2)/0.2,0,1) * (clamp(map(p+n*2.0)/2.0,0,1)*0.5+0.5);
  
  vec3 diff=vec3(0.7);
  diff=mix(diff, vec3(0.5,1.0,0.5), issol);
  vec3 cc=vec3(1,0.5,0.2);
  float g=floor(pp);
  cc.xy *= rot(g);
  cc.xz *= rot(g*0.7);
  cc=abs(cc);
  diff=mix(diff, cc, isvoit);
  col += max(0, dot(n,l)) * diff * shad * ao;
  
  vec3 sky = mix(vec3(0.5,0.6,1)*0.8, vec3(1.0,0.5,0.2)*10.0 , pow(max(0,dot(l,r)), 3));
  col += (-n.y*0.5+0.5) * diff * 1.2 * ao;
  
  col *= fog;
  
  col += pow(1-fog,3) * 1.1 * sky;
      
  col *= 1.2-length(uv);
  
  col = smoothstep(0,1,col*1.2);
  col = pow(col, vec3(0.4545));

  col *= 1;
  out_color = vec4(col, 1);
}