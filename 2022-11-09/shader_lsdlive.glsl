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

in vec2 out_texcoord;
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
	float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
	return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float circle(vec2 p, float r)
{
  return length(p) - r;
}

vec2 pix = vec2(100, 120);

float merge(float t1, float t2, float r)
{
    vec2 v = min(vec2(t1 - r, t2 - r), vec2(0));
    return max(min(t1, t2), r) - length(v);  
}

float outline(float t, float w)
{
  return abs(t) - w;
}

vec3 merge(vec3 base, vec3 col, float t)
{
  return mix(base, col, t > 0);
}

float pla(vec2 uv) {
  return sin(uv.x * 17 + uv.y * -6 + 18 * fGlobalTime)
       + sin(uv.y * 3 + 10 * fGlobalTime)
       + sin(uv.y * 7 + 5 * fGlobalTime)
       + sin(uv.x * uv.x * 0.1) + sin(uv.y * uv.y * 16)
         + uv.x * 3 + uv.y * 2
       + sin(dot(uv,uv)+fGlobalTime)*30
         + fGlobalTime * (0.15 + 0.012 * uv.x + 0.01 * uv.y);
}

float bayer2(vec2 uv) {
  int x = int(uv.x * pix.x + pix.x) % 2;
  int y = (int(uv.y * pix.y + pix.y)) % 2;
  return float(x) + float(y)/2;
}

float bayer(vec2 uv) {
  return bayer2(uv) + 0.25 * bayer2(uv*2);
}

vec3 ramp(float t) {
   return 0.5 * vec3(sin(t/2), sin(t/3+1), sin(t/4+3)) + vec3(0.5);  
}

vec3 cl(vec3 c, vec2 uv) {
   return c - (fract(c * 5) + bayer(uv))/5;  
}

vec3 red = vec3(1.0, 0.0, 0.0);

mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c, s, -s, c);}


float re(float p,float d){return mod(p-d*.5, d) -d*.5;}
void mo(inout vec2 p, vec2 d){
  p=abs(p)-d;
  if(p.y>p.x)p=p.yx;}

float sc(vec3 p, float d){
  p=abs(p);
  p=max(p, p.yzx);
  return min(p.x, min(p.y, p.z))-d;
}

void amod(inout vec2 p, float m){
  float a = re(atan(p.x,p.y), m);
  p=vec2(cos(a),sin(a))*p;
}
float pi = 3.141592;
float de(vec3 p){
  //p.y+=.7;
  //p.xz*=r2d(fGlobalTime);
  p.xy*=r2d(fGlobalTime*.3);

  
  vec3 q =p;
  amod(p.xy, pi/3);
  
  //mo(p.xz, vec2(1));
  mo(p.xy, vec2(.5));
  mo(p.xy, vec2(14));
  
  amod(p.xy, pi/5);
  p.x=abs(p.x)-.5;
  p.z=re(p.z, 6.);
  
  
  q.xy*=r2d(q.z*.2);
  float d = sc(p, .3);
  
  q.x = abs(q.x) - 1.;
  return min(d, length(q.xy)-.3);
  return length(p)-1;
}

void main(void){
vec2 uv = out_texcoord;
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro=vec3(0,  0,-3+fGlobalTime*7), rd=normalize(vec3(uv, 1)), p;
  float t=0.,i=0;
  for(;i<1.;i+=0.01){
  p=ro+rd*t;
    float d=de(p);
    if(d<.01)break;
    t+=d;
    }

  out_color.rgb = vec3(1-i);
  out_color.a = 1.0;
  }


  /*
void main2(void)
{
  // I have no idea what I'm doing
	vec2 uv = out_texcoord;
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  float shade = pla(uv);
  vec3 bg = ramp(shade + 1.0 * bayer(uv));
  
  uv -= fract(uv * pix) / pix;
  vec3 col = bg;
 
  for (int i = 0; i < 5; ++i) {
    float t = 1000.0;
    float a = 0;
    for (int j = 0; j < 5; ++j) {
      vec4 s0 = texture2D(texNoise, vec2(i,j)/10);
      vec4 s1 = texture2D(texNoise, vec2(i,j)/5);
      vec2 c0 = vec2(sin(fGlobalTime * 0.5 + 2*i+5*j), cos(fGlobalTime * 0.5 + 3*i+j*2)) * vec2(2, 1.0);
      vec2 c = c0+ vec2(sin(fGlobalTime * 5 + j-i), cos(fGlobalTime * 5 + i+j)) * vec3(0.3);
      float t2 = circle(uv + (0.2+ 0.2*sin(fGlobalTime + 5.0*s0.x+i+j)) * c, (1.0+sin(12*i+s1.y+3*fGlobalTime+15*s1.z))*0.1);
      t = merge(t, t2, 0.1);
    }
    col = merge(col, cl(ramp(fGlobalTime*5+4.3*i+t*20), uv), -t);2@
    t = outline(t,0.005);
    col = merge(col, vec3(0.0), -t);
  }
  /*
    float t1 = circle(uv + vec2(sin(fGlobalTime), cos(fGlobalTime)) / 3, 0.2 * (2 + sin(fGlobalTime)));
  float t2 = circle(uv + vec2(sin(2 * fGlobalTime + 3), cos(3 * fGlobalTime + 3)) / 3, 0.2);
  //float t2 = circle(uv + vec2(0.2), 0.2);
  float t = merge(t1, t2, 0.1);
  t = outline(t, 0.005);
  col = merge(col, vec3(0), -t);
    */
//  float t = outline(circle(uv, 0.2), 0.01);
  //col = merge(col, red, circle(uv + vec2(0.1), 0.2));
  //out_color.rgb = col;
  //mix(col, red, t > 0);
  /*out_color.rgb = col;
  out_color.a = 1.0;
}*/