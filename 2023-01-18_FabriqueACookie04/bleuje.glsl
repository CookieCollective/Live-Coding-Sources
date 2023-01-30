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

vec4 plas( vec2 v, float time )
{
	float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
	return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float time;

float sdSphere(vec3 p,float r)
{
  return length(p)-r;
}

float sdBox(vec3 p,vec3 b)
{
  vec3 q = abs(p)-b;
  return length(max(q,0.))+min(0.,max(q.x,max(q.y,q.z)));
}

struct MapData
{
  float dist;
  float type;
  vec2 UV;
};

float objectSize = 0.3;
float spacing = 5.0;

mat2 rot(float angle)
{
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c,-s,s,c);
}

#define PI 3.141592

vec3 rollPosition(vec3 q,float param, float delay)
{
  param -= delay; 
  float stp = floor(param);
  float transition = param-stp;
  
  transition = pow(transition,3.0);
  
  q -= vec3(-objectSize*0.5+0.25,0.,0.);
  q -= vec3(2.0*objectSize*(stp-param),0.,0.);
  q -= vec3(objectSize,0.,-objectSize);
  q.xz *= rot(PI/2.0*transition);
  q += vec3(objectSize,0.,-objectSize);
  q.xz *= rot(-PI/2.0*stp);
  
  return q;
}

MapData map(vec3 p)
{
  MapData res;
  
  p.yz *= rot(-0.25*PI);
  
  vec3 q = p;
  
  float repLen = objectSize*spacing;
  
  vec2 qi = floor((q.xy+vec2(repLen)/2.0)/repLen);
  
  float type = mod(qi.x+qi.y,2.0);
  
  p.z += 0*0.25*sin(2.*PI*(time-0.1*length(qi)));
  
    p.xy = mod(p.xy+repLen/2.0,repLen)-repLen/2.0;
    
  float delay = 0.2*length(qi);
  
  if(false && type==0.)
  {
    p = rollPosition(p,2.*time+0.5,delay);
    res.dist = sdBox(p,vec3(objectSize));
  }
  else
  {
   p = rollPosition(p,2.*time,delay);
   res.dist = sdBox(p,vec3(objectSize));
    vec2 UV;
    UV = p.xy/objectSize;
    res.UV = UV;
  }
    
    return res;
}

vec3 getNormal(vec3 p)
{
  vec2 off = vec2(0.001,0);
  return normalize(map(p).dist-vec3(map(p+off.xyy).dist,map(p+off.yxy).dist,map(p+off.yyx).dist));
}

void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  time = 0.5*fGlobalTime;
  
  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv*1.,1.0));
  
  MapData res;
  float t = 0.;
  bool hit = false;
  vec3 pos;
  for(float i=0.;i<1.0;i+=1.0/60.)
  {
    pos = ro + t*rd;
    res = map(pos);
    if(res.dist<0.001)
    {
      hit = true;
      break;
    }
    t += 0.8*res.dist;
  }
  
  vec3 col = vec3(0.);
  
  if(hit)
  {
    vec3 col1 = 0.5*getNormal(pos)+0.5;
    vec3 col2 = col1.yzx;
    float len = length(res.UV)*4;
    float mxer = sin(PI*2.*len)*0.5+0.5;
    col = mix(col1,col2,mxer);
  }
  
  out_color = vec4(col,1.0);
  
/*  
	vec2 m;
	m.x = atan(uv.x / uv.y) / 3.14;
	m.y = 1 / length(uv) * .2;
	float d = m.y;

	float f = texture( texFFT, d ).r * 100;
	m.x += sin( fGlobalTime ) * 0.1;
	m.y += fGlobalTime * 0.25;

	vec4 t = plas( m * 3.14, fGlobalTime ) / d;
	t = clamp( t, 0.0, 1.0 );
	out_color = f + t;
*/
  }