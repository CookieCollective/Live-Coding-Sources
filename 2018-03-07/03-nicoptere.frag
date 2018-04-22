
precision mediump float;

uniform float time;
uniform vec2 resolution;


float noise (vec3 p ){
vec4 a = dot( floor( p ), vec3( 1.,57.,21.) ) + vec4( 0.,57.,21., 78. );
vec3 f = -.5 * cos( fract( p ) * acos( -1. ) ) + .5;
a = mix( sin( cos( a ) * a ), sin( cos( 1. + a ) * (1. + a )) , f.x);
a.xy = mix( a.xz, a.yw, f.y );
return mix( a.x, a.y, f.z );

}
float fbm( vec3 p ){
  float v = 0.;
  float a = .5;
  for( int i =0; i < 4; i++ ){
    v += a * noise( p );
    p *= 2.;
    a *= .5;

  }
  return v;
}


float blend( float a, float b, float k ){

  float h = clamp( ( b-a )/k, 0.,1. );
  return mix( b, a, h)-k*h*(1.-h);

}

float map( vec3 p ){

  float st = abs( sin( time ) );
  vec3 off = vec3(0.,st *5., 0.) ;
float s = length( p + off ) - 3.;
  float n = fbm( p + time );
  float pl = dot( p, vec3(0.,1.,0.)) + 1.;
  return n + blend(  s , pl, st  );
}

void main () {
  vec2 uv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
uv.x *= resolution.x / resolution.y;

float t =0.;

  vec3 o = vec3( 0., 0., -5.);
  vec3 d = vec3( uv, 1.);
  vec3 p;
  float v;
  for ( int i =0; i < 16; i++ ){
    p = o + d* t;
    v = map(p);
    if( v < 0.01 )break;
    t += v;
  }

vec3 col = vec3(1. - t/16. );



  gl_FragColor = vec4(col, 1);
}
