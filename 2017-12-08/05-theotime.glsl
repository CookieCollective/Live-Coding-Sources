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
float c = cos(a), s = sin(a);
return mat2(c, s, -s, c);
}

float de(vec3 p) {

//p.xy *= r2d(1/1e5*fGlobalTime);

p.x = abs(p.x) - 25;

p.xz *= r2d(3.14/4);


p = mod(p+30, 60) - 30;


vec3 q = p;


p.y += sin(p.x*3.);


float r= 15 + 3*pow(.5+.5*sin(15*fGlobalTime), 4);


p.z*=2-p.y/15;
p.y = 4 + 1.2 * p.y - abs(p.x) * sqrt(max((20 - abs(p.x))/15, 0));

float sph = length(p) - r;
float sph2 = length(q) - 9.;



q.y -= 7.;
q.x -= 7.;
float sph4 = length(q.xy + cos(fGlobalTime)) - 3.;
q.x+= 14.;
float sph5 = length(q.xy - cos(fGlobalTime)) - 3.;

float d = max(sph, -sph2);
d = max(d, -sph4);
d = max(d, -sph5);

return d/3.;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

vec3 ro = vec3(cos(fGlobalTime)*20, fGlobalTime*50, -50*sqrt(abs(tan(fGlobalTime))));
vec3 rd = normalize(vec3(uv, -1)), p;
p = ro;

float i=0;
for(;i<1;i+=.01) {
float d= de(p);
if(d<.01) break;
p+=rd*d;
}



vec3 c = mix(vec3(.9, .3, .5), vec3(.2, .1, .2), i);
c = mix(c, vec3(.2, .1, .2), 1 - exp(-.005 * length(ro-p)));

  out_color = vec4(c, 1);
}