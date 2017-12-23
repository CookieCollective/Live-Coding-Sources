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


mat2 r2d(float a){
float c=cos(a), s=sin(a);
return mat2(c, s,-s, c);
}

float sc(vec3 p){
p = abs(p);
p = max(p,p.yzx);
return min(p.x, min(p.y, p.z)) - .31;
}

float de(vec3 p){


p.y += cos(fGlobalTime)*.1;
//p.x += cos(fGlobalTime)*.1;

p.x = abs(p.x) - .3;



p.xy *=r2d(fGlobalTime +p.z + p.y);

float s=1.;
float d = 0;
vec3 q = p;
for(int i =0;i<5;i++){
q = mod(p*s+1, 2) - 1;
d = max(d, -sc(q)/s);
s+=3;
}
return d;
}


void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

vec3 ro = vec3(0, 0, -fGlobalTime-tan(fGlobalTime)),p;
vec3 rd = normalize(vec3(uv, -1));
p = ro;

float i = 0;
for(;i<1;i+=.01){
float d = de(p);
if(d<.0001) break;
p+=rd*d;
}
i/= sqrt(abs(tan(fGlobalTime*4.) + p.x*p.x + p.y*p.y)) *.1;

vec3 c = mix(vec3(.7, .3, .2), vec3(.1, .1, .2), i*sin(p.z));
//c *= texture(texNoise, p.xz).x;
c *= pow(length(ro-p), 1.1);


  out_color = vec4(c, 1);
}