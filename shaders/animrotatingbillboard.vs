uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;
uniform vec3 FLOAT_PARAMS;

#define X FLOAT_PARAMS.x
#define Z FLOAT_PARAMS.y
#define R FLOAT_PARAMS.z
attribute vec4 POS2D_UV;                  // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

#if defined( FADE_OUT )
    uniform mat4 STATIC_WORLD_MATRIX;
    varying vec2 FADE_UV;
#endif

#if defined( UI_HOLO )
	varying vec3 PS_TEXCOORD1;
#endif

#if defined( HOLO )
	float filmSkipRand() // This should match the function with the same name in anim.ps
	{
		float steps = 12.;
		float c = fract(sin(ceil(TIMEPARAMS.x * steps) / steps) * 10000.);
		return (c * -.36) * step(.78, c);
	}
#endif

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

    mat3 flip_back = mat3(
    	vec3(1.0, 0.0, 0.0),
    	vec3(0.0, 0.0, 1.0),
    	vec3(0.0, -1.0, 0.0));

    mat3 rot = mat3(
    	cos(R), 0.0, sin(R),
    	0.0, 1.0, 0.0,
    	sin(R), 0.0, -cos(R));

    vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	vec3 origin = vec3(X, 0, Z);
	vec3 offset = world_pos.xyz - origin;
	vec3 offset_trans_3 = rot* flip_back* offset;
	offset_trans_3 += vec3(0.0, offset_trans_3.y * - 0.074074074, 0.0); // 1 - 1 / 1.108
	offset_trans_3 += vec3(offset_trans_3.y * -0.5, 0.0, 0.0);
	world_pos.xyz = offset_trans_3 + origin;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	#if defined( HOLO )
		float filmSkipOffset = sin(filmSkipRand()) * .4;
		gl_Position.y += filmSkipOffset;
	#endif

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;

#if defined( FADE_OUT )
	vec4 static_world_pos = STATIC_WORLD_MATRIX * vec4( POSITION.xyz, 1.0 );
    vec3 forward = normalize( vec3( MatrixV[2][0], 0.0, MatrixV[2][2] ) );
    float d = dot( static_world_pos.xyz, forward );
    vec3 pos = static_world_pos.xyz + ( forward * -d );
    vec3 left = cross( forward, vec3( 0.0, 1.0, 0.0 ) );

    FADE_UV = vec2( dot( pos, left ) / 4.0, static_world_pos.y / 8.0 );
#endif

#if defined( UI_HOLO )
	PS_TEXCOORD1 = gl_Position.xyw;
#endif
}