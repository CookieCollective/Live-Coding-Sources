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

const float pi = acos(-1);

float tt = .4*mod(fGlobalTime, pi*100.);
float rt = floor(tt);
float ft = fract(tt);
float t = rt + ft*ft;

mat2 rot(float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s, c); }
float torus(vec3 p, float r, float s) { vec2 b=vec2(length(p.xy)-r, p.z); return length(b)-s; }

vec2 moda(vec2 p, float r) {
  r = 2*pi/r;
  float a = mod(atan(p.y, p.x), r) - r*.5;
  return vec2(cos(a), sin(a))*length(p);
}

float glowAccumulator = 0;
float scene(vec3 p) {
  vec3 po = p;
  
  p.y = mod(p.y+t, 2.)-1.;
  
  p.xz *= rot(tt);
  
  p.xz = moda(p.xz, 4. + (mod(tt*2, 5)));
  p.yz = moda(p.yz, 4. + (mod(tt*2, 7)));
  
  float tr = torus(p, 2.+.5*sin(tt), .01);
  float pl = dot(abs(p), vec3(0, .4, 1.))-.1;
  float o = max(tr, pl)-.2;
  
  // lets make it glow even more :D
  po.y -= sin(10*t+po.y);
  po.xz += .2*sin(2*t+po.y);
  float glo = length(po.xz)-.2;
  po = p;
  po.y += .05*sin(10*t+po.x*po.z);
  glo = min(glo, length(po.yz))-.01;
  glowAccumulator+= .03/(.01+abs(glo));
  
  return min(o, max(glo, .01));
}

vec3 getCamera(vec2 pixelCoord, vec3 origin, vec3 target, float zoom) {
  vec3 forward = normalize(target-origin);
  vec3 side = normalize(cross(vec3(0,1,0), forward));
  vec3 up = normalize(cross(forward, side));
  return normalize(forward*zoom+pixelCoord.x*side+pixelCoord.y*up);
}

vec3 calculateNormalUsingGradientsAt(vec3 p) {
  vec2 eps = vec2(0, .001);
  return normalize(vec3(scene(p) - vec3(scene(p-eps.yxx), scene(p-eps.xyx), scene(p-eps.xxy))));
}

#define fakeAmbiantOcclusion(a) clamp(scene(hitPoint+normalAtHitpoint*a)/a, 0., 1.)
#define fakeSubSurfaceScattering(a) smoothstep(0., 1., scene(hitPoint+lightDirection*a)/a)
void main(void)
{
  vec2 currentPixelCoord = (gl_FragCoord.xy / v2Resolution.xy - .5) * vec2(v2Resolution.x/v2Resolution.y, 1);
  
  vec3 eye = (15+5*cos(t+sin(t))) * vec3(0, 0, .5);
  vec3 target = vec3(0);
  target.xz += vec2(sin(t), cos(t));
  target.y += 6*sin(t);
  
  
  float idx = mod(floor(tt*5), 11);
  if(idx == 0) {
    currentPixelCoord.x = abs(currentPixelCoord.x);
  }
  if(idx == 1) {
    currentPixelCoord = abs(currentPixelCoord);
  }
  if(idx > 2 || idx < 6) {
    currentPixelCoord *= 1. - length(currentPixelCoord)*.7;
  }
  if(idx > 6) {
    currentPixelCoord /= 1. - length(currentPixelCoord)*.10;
  }
  
  vec3 rayDirection = getCamera(currentPixelCoord, eye, target, .8);
  
  float clouds = texture(texNoise, .7*abs(vec2(atan(rayDirection.y, rayDirection.z), rayDirection.x))).r;
  vec3 color = vec3(pow(1.8*clouds, 4));
  
  vec3 lightPosition = 10*vec3(1,1,-1);
  
  float hitDistance = 0;
  vec3 hitPoint = eye; // < start from eye position
  int i = 0;
  for(i=0; i<300; i++) {
    float closestHit = scene(hitPoint)*.7;
    if(abs(closestHit)<.001) {
      vec3 normalAtHitpoint = calculateNormalUsingGradientsAt(hitPoint);
      vec3 lightDirection = normalize(lightPosition-hitPoint);
      float diffuse = max(0, dot(normalAtHitpoint, lightDirection));
      float specular = pow(max(0, dot(rayDirection, reflect(lightDirection, normalAtHitpoint))), 50);
      color = vec3(diffuse)*fakeSubSurfaceScattering(.4);
      color *= .2+.2*(fakeAmbiantOcclusion(.1)+fakeAmbiantOcclusion(.3));
      color += vec3(specular);
      break;
      
    }
    if(hitDistance>100.) break;
    
    hitDistance += closestHit;
    hitPoint += rayDirection * closestHit;
  }
  color += vec3(1.4, .1, .5)*pow(i * .007, .9);
  
  color += vec3(.0002+.0001*sin(t*10))*pow(glowAccumulator, 3)*normalize(acos(-rayDirection));
  
  out_color = vec4(color, 1);
}