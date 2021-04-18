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

float donut(vec3 p, vec2 t){ return length(vec2(length(p.xz)-t.x,p.y))-t.y;}
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

vec2 Dist(vec3 p){
  vec2 a = vec2(donut(p,vec2(1,0.5)),2.0);
  vec2 b = vec2(length(p+vec3(0,1.0-abs(sin(fGlobalTime))*3.0,0))-0.5,1.0);
  b = (b.x < a.x) ? b:a;
  //a = vec2(length(p+vec3(0,5.0,0))-0.5,3.0);
  //b = (b.x < a.x) ? b:a;
  return b;
}
vec2 Dist2(vec3 p){
  float t= mod(fGlobalTime,200.0);
  t = fract(t)*fract(t)+floor(t);
  vec3 p2 = p;
  float modd = 45.0;
  vec3 id = floor((p2+modd*0.5)/modd);
  t+= id.x*2.0;
  t+= id.z*2.0;
  p2.yz*=rot(sin(t)*0.2);
  p2.y +=sin(id.x+t)*12.0;
  p2 = mod(p2+modd*0.5,modd)-modd*0.5;
  for(int i = 0; i < 4; i++){
    p2 = abs(p2)-vec3(2,1,1);
    p2.xy *=rot(0.5);
    p2.zy *=rot(0.5+sin(t)*2.0);
    p2.zx *=rot(0.5);
  }
  return Dist(p2);
}
void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  float t = mod(fGlobalTime,200.0);

  vec3 ro = vec3(t*3.0,0,-30);
  vec3 rd = normalize(vec3(uv,1));
  
  float dO = 0.0;
  float shad = 0.0;
  vec2 obj;
  for(int i = 0; i <128; i++){
    vec3 p = ro + rd*dO;
    obj = Dist2(p);
    dO += obj.x;
    if(obj.x <0.001|| dO>300.0){
      shad = float(i)/128.0;
      break;
    }
  }
 
  vec3 col = vec3(0);
 
 if(obj.y == 1.0){
   shad= 1.0-shad;
   col = vec3(shad)*vec3(0.2,0.5,0.8);
 }
 if(obj.y == 2.0){
   shad= shad;
   col = vec3(shad)*vec3(0.8,0.2,0.9);
 }
 //if(obj.y == 3.0){
 //  shad= shad;
 //  col = vec3(shad)*vec3(1)*3.0;
 //}
col = mix(col,vec3(0),clamp(dO/300.0,0,1));
 
 
out_color = vec4(col*2.0,0.0);
}
