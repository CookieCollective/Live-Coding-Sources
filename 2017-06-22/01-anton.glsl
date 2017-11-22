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


vec2 rot(vec2 v, float a)
{
  float sa = sin(a);float ca = cos(a);
  return mat2(ca,-sa,sa,ca) * v;
}

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything
float  map(vec3 pos,out float id)
{


  vec3 cp = pos;

  cp.y-= abs(cp.x * .7);
  float f1 = distance(cp, vec3(0.,0.,10.)) - 1.;

  float d = abs(pos.x); 

  float n = texture(texNoise,pos.xz  * .01+ vec2(0.,fGlobalTime * .1)).z * (2. + d);


  float f2 = distance(pos.y, -2. - n);


  id = step(f1,f2);
  return min(f1, f2);

}

int STEP = 128;
float ESP = .001;

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  vec3 ro = vec3(uv,-5.);
  vec3 rd = normalize(vec3(uv, 1.));

  vec3 cp =  ro;

  float cd;
  int cs = 0;
float id ;
  for(; cs < STEP; ++ cs)
  {
    cd = map(cp,id);
    if(cd < ESP)
      break;
    cp += rd * cd * .5;
  }
  float f = 1.-float(cs) / float (STEP);
  
  vec4 sc = mix(vec4(.8,.9,.3,1.),vec4(.2,.4,.7,1.),sin((fGlobalTime - cp.z)*.05));
  vec2 uv2 = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  vec4 tex = texture(texPegasus,uv2 * vec2(1.,-1.) + vec2(0.,sin(uv2.x  * 4.+ fGlobalTime * 1.)*.1));


  out_color = mix(vec4(1.,0.,.3,1.),sc,1.-id);
  if(cd > 1.)
  out_color = mix(out_color,tex,1.-f);

}