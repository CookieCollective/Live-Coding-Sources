Texture2D texChecker;
Texture2D texNoise;
Texture2D texTex1;
Texture2D texTex2;
Texture2D texTex3;
Texture2D texTex4;
Texture1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
Texture1D texFFTSmoothed; // this one has longer falloff and less harsh transients
Texture1D texFFTIntegrated; // this is continually increasing
SamplerState smp;
#define time fGlobalTime

cbuffer constants
{
  float fGlobalTime; // in seconds
  float2 v2Resolution; // viewport resolution (in pixels)
}

float4 plas( float2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return float4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

float getHash(float2 pos) 
{
   return frac(sin(floor((pos.x)*1258.8)*896) + sin(floor(pos.y*876.7623))*456);
}

float getNoise(float2 pos)
{
  float2 fPos = frac(pos);
  float2 iPos = floor(pos);

  return lerp(
        lerp(getHash(iPos)           , getHash(iPos+float2(1,0)), fPos.x), 
        lerp(getHash(iPos+float2(0,1)), getHash(iPos+float2(1,1)), fPos.x), fPos.y);
}

float getMNoise(float2 pos)
{
  float val=0.0f;
  float it = 1.0f;
  
  for(int i=0;i<4; i++)
  {
    val += getNoise(pos)*it;
    pos *= 2.0f;
    it *=0.5f;
  }
  return val;
}

float2x2 rot(float angle)
{
    return float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));  
}


float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
  float2 uv = TexCoord;
  uv -= 0.5;
  uv /= float2(v2Resolution.y / v2Resolution.x, 1);

  float2 oUV = uv;
  
  float r = getMNoise(uv*8);
  
  uv = mul(rot(r+time),uv);
  uv = abs(uv);
  uv.x += frac(time*.5);

  uv = mul(rot(time*2.2), uv);
  
  float4 col;
  col.r = getMNoise(uv*4);
  col.g = getMNoise(uv*4.5);
  col.b = getMNoise(uv*5);
  col.a = 1;
  
  col *= smoothstep(-0.5, 0, oUV.y);
  col *= smoothstep(0.5, 0, oUV.y);
  
  return col;
}