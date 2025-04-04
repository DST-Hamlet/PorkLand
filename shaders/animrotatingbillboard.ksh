   animrotatingbillboard
      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                FLOAT_PARAMS                            SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                COLOUR_XFORM                                                                                PARAMS                        OCEAN_BLEND_PARAMS                                OCEAN_WORLD_EXTENTS                                animrotatingbillboard.vs.	  uniform mat4 MatrixP;
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
}    animrotatingbillboard.psj  #if defined( GL_ES )
precision mediump float;
#endif

uniform mat4 MatrixW;

#if defined( TRIPLE_ATLAS )
    uniform sampler2D SAMPLER[6];
#else
    uniform sampler2D SAMPLER[5];
#endif

#ifndef LIGHTING_H
#define LIGHTING_H

#if !defined( UI_CC )
// Lighting
varying vec3 PS_POS;
#endif

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

#if defined( UI_CC )
vec3 CalculateLightingContribution(vec2 pos)
{
	vec2 uv = ( pos - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}
#else
vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;
	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}
#endif

#endif //LIGHTING.h


varying vec3 PS_TEXCOORD;

uniform vec4 TIMEPARAMS;
uniform mat4 COLOUR_XFORM;
uniform vec2 PARAMS;
uniform vec3 FLOAT_PARAMS;
uniform vec4 HAUNTPARAMS;
uniform vec4 HAUNTPARAMS2;
uniform vec4 OCEAN_BLEND_PARAMS;
uniform vec3 CAMERARIGHT;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y

uniform vec4 OCEAN_WORLD_EXTENTS;
#define OCEAN_SAMPLER SAMPLER[4]

void main()
{
    vec4 colour;

#if defined( TRIPLE_ATLAS )
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else if( PS_TEXCOORD.z < 1.5 )
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[5], PS_TEXCOORD.xy );
    }
#else
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
#endif

    // if(FLOAT_PARAMS.y > 0.0)
    // {
    // 	if(PS_POS.y < FLOAT_PARAMS.x)
    // 	{
    // 		discard;
    // 	}
    // }

#if defined ( FADE_OUT )
	if (colour.a >= ALPHA_TEST)
#else
	if (ALPHA_TEST > 0.0)
	{
		if (colour.a >= ALPHA_TEST)
		{
			gl_FragColor = colour.rgba;	
		}
		else
		{
			discard;
		}
	}
    else
#endif
    {
        gl_FragColor.rgba = colour.rgba * COLOUR_XFORM;
		
		vec2 world_uv = ( PS_POS.xz - OCEAN_WORLD_EXTENTS.xy ) * OCEAN_WORLD_EXTENTS.zw;
		vec3 world_tint = texture2D( OCEAN_SAMPLER, world_uv ).rgb;
		gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb * world_tint.rgb, OCEAN_BLEND_PARAMS.x);

        vec3 light = CalculateLightingContribution();

        gl_FragColor.rgb *= max( light.rgb, vec3( LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE ) );
    }
#if defined ( FADE_OUT )
	else
	{
		discard;
	}
#endif

}                                   	   