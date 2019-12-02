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

float Spaget(float2 pos, float offset)
{
  
  float2 uvPos = 0.5 + float2(sin(pos.x * 6.28f)*0.03, cos(pos.x * 6.28f)*0.03);
  
    float val = texNoise.Sample(smp, uvPos+float2(0.0f, offset));
//    float val = texNoise.Sample(smp, float2(pos.x, 0.0f));
    
    return val;
  
}



float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
  float2 uv = TexCoord;
  uv -= 0.5;
  
  uv /= float2(v2Resolution.y / v2Resolution.x, 1);
  
  float4 col1 = float4(0.1, 0.3, 0.6, 1);
  float4 col2 = float4(0.8, 0.2, 0.1, 1);
  
  float4 col=col1;
  
//  col = lerp(col, float4(0.8, 0.7, 0.0, 1.0), smoothstep(0.2, 0.3, length(uv));
  
  
  for (int i=0;i<10;i++)
  {
    float2 finalUV = uv + float2(fGlobalTime*(i+3)*0.05, 0.0);
    finalUV.x *= 0.5;
    
    float val = Spaget(finalUV, i*0.05)-0.25-i*0.02;
    val *=2;
    float3 locColor = lerp(col1, col2, i*0.18);
    locColor *= smoothstep(-1.0,0.5, uv.y);
    
    
    
    
    col.rgb = lerp(col.rgb, locColor, (smoothstep(-1,val, uv.y)) * (smoothstep(val+0.15,val+0.145, uv.y)));
    
  }
  
  
  
  return col;
}