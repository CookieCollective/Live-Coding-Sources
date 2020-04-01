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

#define time fGlobalTime

float sdBox(vec2 p, vec2 s){
    p = abs(p) - s;
    return max(p.x, p.y);
}

float xor(float x,float y){
  return float(int(x)*int(y));
  }

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  
  //uv.xy *= rot(time*0.00004 + q.y*0.01);
  
  vec3 col = vec3(0);
  vec2 p = uv;
  #define pal(a,b,c,d,e) (a + b*sin(c*d + e))
  #define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
  
  float d = 10e7;
  vec2 q = vec2(10.*atan(p.x,p.y)/6.28, length(p));
    
  q.y = log(q.y) + time*1.11 + texture(texFFT, 0.1).x*10.5 ;
  
  float id = floor(q.y*10.);
  q.xy *= rot(time*0.00004 + q.y*0.0001);
  q = sin(q*3.);
  q = sin(q*1. + time);
  
  float a = 0.;
  
  
  for(float i = 0.; i < 20.; i++){
    
    //q = abs(q);
    if(q.x < q.y)
      q.xy = q.yx;
    
    float m = 100.;
    float x = xor(q.y*m,q.x*m);
    
    q.x *= 1. ;
    
    
    if(mod(x*2., 1.) < 1.){
      //float circ = exp(-length(sin(q*1. + time))*20.);
      float circ = exp(-length(sin(q*1. + time))*20.);
      col += circ * pal(0.5,1.,vec3(0.2,0.3,0.5), 0.7 ,0.4 + id*0.5);
      //d = min(d, length(q) - 10.5);
      
      }
    q -= 0.15;
    q -= 0.5;
    if(mod(i,3. ) == 0 && x > 0.4){
      d = min(d, sdBox(mod(q,1.) - 0.5, vec2(0.9)));
      a += x;
      }
    else{
      d = max(d, -sdBox(mod(q,1.) - 0.5, vec2(0.3)));
      a += x;
    }
    q.xy *= rot(0.125*3.14);
    
  }
  
  
  
  col += smoothstep(0.001,0., d);
  
  if(d < 0.001)
    col *= pal(0.1,1.,vec3(0.2,0.3,0.5), 0.7 ,0.4 + floor(id)*1. + time);
  
  
  
  col = col;
  col = max(col, 0.);
  
  
  
  
  out_color += col.xyzy;
  
}