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

vec2 getPos(float time)
{
  if(time<1) return vec2(0,time);
  else if(time<1.3) return vec2(time-1,1);
  else if(time<1.8) return vec2(0.3, 1.3-time);
  else if(time<2.0) return vec2(2.1-time,0.5);
  else if(time<2.5) return vec2(0.1, 2.5-time);
  else return vec2(2.6-time,0);
}

vec4 getColor(vec2 pos)
{
  vec2 track[7];
  track[0]=vec2(0,0);
  track[1]=vec2(0,1);
  track[2]=vec2(0.3,1);
  track[3]=vec2(0.3,0.5);
  track[4]=vec2(0.1,0.5);
  track[5]=vec2(0.1,0);
  track[6]=vec2(0,0);

  bool ok=false;
  int i;
  for(i=0;i<6;i++)
  {
    vec2 dp = pos-track[i];
    dp=normalize(dp);
    vec2 segment = track[i+1] - track[i];
    float segmentLength = sqrt(dot(segment,segment));
    float dotp = dot(dp, segment);
    if(dotp>0 && dotp < segmentLength)
    {
      vec2 segmentPos = dp + segment * (dotp / segmentLength);
      dp = pos - segmentPos;
      float distSqr = dot(dp,dp);
      if(distSqr < 0.1) ok = true;
    }
  }
  return ok ? texture(texChecker, pos) : vec4(0,0,0,1);
}

void main(void)
{
  vec2 screenCoords = gl_FragCoord.xy / v2Resolution;
  screenCoords -= 0.5;

  vec2 texPos = vec2(screenCoords.x, 1);
  texPos.x /= screenCoords.y;
  texPos.y /= screenCoords.y;
  vec2 pos = getPos(mod(fGlobalTime * 0.1,2.6));
  texPos += pos * 10;

  out_color = screenCoords.y < 0 ? getColor(texPos) : vec4(0,0,0,1);
}