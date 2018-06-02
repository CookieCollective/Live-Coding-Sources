#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texKC;
uniform sampler2D texNoise;
uniform sampler2D texPegasus;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

#define time fGlobalTime

float sph(vec3 p, float r) {

  return length(p)-r;
}

float cyl(vec2 p, float r) {
  return length(p)-r;
}

mat2 rot(float a) {
  float co=cos(a);
  float so = sin(a);
  return mat2(co,so,-so,co);
}

vec3 rep(vec3 p, vec3 s) {

  return (fract(p/s+.5)-0.5)*s;

}

float map(vec3 p, inout float v) {

  vec3 r1 = rep(p, vec3(10.0));

  

  float d = sph(r1, 0.5);

  d = max(d, -cyl(p.xy,0.3));

  for(int i=0; i<13; ++i) {

    float a = i * sin(time + cos(time)*0.3);
     float j = sin( time*0.1)*1.0;
    vec3 l =p + vec3(cos(a)*j,sin(a)*j, 0.2);
    vec3 k =l;
    k.xz *= rot(time*0.1);

    d = min(d, sph(k,0.0));
  
  }

  v = 0.0;

  for(int i=0; i<13; ++i) {
  
    vec3 r2 = rep(p, vec3(5.0));
    vec3 sp = r2 + vec3(sin(time),0,0);
    sp.xy *= rot(0.3 * sin(time*i + i *1243.5467));
    sp.yz *= rot(0.3 * sin(time*0.3*i + i *1243.5467));
    d = min(d, cyl(sp.xz,0.1));

    

  }


  return d;

}

vec3 norm(vec3 p) {


  float v=0.0;
  float base = map(p,v);
  vec2 off = vec2(0.0,0.01);
  
  return normalize(vec3(base-map(p-off.yxx,v),base-map(p-off.xyx,v),base-map(p-off.xxy,v)));

}

vec3 march(vec3 ro, vec3 rd) {

  vec3 col = vec3(0.0);

  float e=0.0;
  vec3 p = ro;
  for(int i=0;i<200; ++i) {

    float v = 0.0;
    float d = map(p,v);

    if(d<0.0001) {

      vec3 n = norm(p);
      float lum = dot(n, normalize(-vec3(0.7)))*0.8+0.2;
      float depth = length(p-ro);
      col = vec3(10.0/(depth));

      break;
    }

    e += 0.0001/d;
  
    p+=d*rd;
  }

  col += e * vec3(0.0,0.2,1.0);;

  return col;
}

void main(void)
{
  vec2 uv = vec2(2.0*gl_FragCoord.x / v2Resolution.x - 1.0, 1.0-2.0*gl_FragCoord.y / v2Resolution.y);
  uv.y *= v2Resolution.y / v2Resolution.x;

  vec3 ro = vec3(0,0,-3);
  vec3 rd = normalize(vec3(uv, 1.0));
  vec3 col = march(ro,rd);



  out_color = vec4(col, 1.0);
}