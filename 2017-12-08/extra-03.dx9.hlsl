texture texTFFT; sampler1D texFFT = sampler_state { Texture = <texTFFT>; }; 
// towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
texture texFFTSmoothedT; sampler1D texFFTSmoothed = sampler_state { Texture = <texFFTSmoothedT>; }; 
// this one has longer falloff and less harsh transients
texture texFFTIntegratedT; sampler1D texFFTIntegrated = sampler_state { Texture = <texFFTIntegratedT>; }; 
// this is continually increasing

texture rawtexChecker; sampler2D texChecker = sampler_state { Texture = <rawtexChecker>; };
texture rawtexNoise; sampler2D texNoise = sampler_state { Texture = <rawtexNoise>; };
texture rawtexTex1; sampler2D texTex1 = sampler_state { Texture = <rawtexTex1>; };
texture rawtexTex2; sampler2D texTex2 = sampler_state { Texture = <rawtexTex2>; };
texture rawtexTex3; sampler2D texTex3 = sampler_state { Texture = <rawtexTex3>; };
texture rawtexTex4; sampler2D texTex4 = sampler_state { Texture = <rawtexTex4>; };

float fGlobalTime; // in seconds
float2 v2Resolution; // viewport resolution (in pixels)

float4 plas( float2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return float4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}
float4 main( float2 TexCoord : TEXCOORD0 ) : COLOR0
{
  float2 uv = TexCoord;
  uv -= 0.5;
  uv /= float2(v2Resolution.y / v2Resolution.x, 1);
  float2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1 / length(uv) * .2;
  float d = m.y;

  float f = tex1D( texFFT, d ).r * 100;
  m.x += sin( fGlobalTime ) * 0.1;
  m.y += fGlobalTime * 0.25;

  float4 t = plas( m * 3.14, fGlobalTime ) / d;
  t = saturate( t );

  float4 col = float4(((uv.x+0.5+sin(fGlobalTime+uv.y*10)/5 + sin(fGlobalTime+uv.y*2.234)/-3)*10)%1, uv.y, 1, 1);
  return col;
}