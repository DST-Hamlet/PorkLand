   interior_wall_particle   	   MatrixPVW                                                                                MatrixW                                                                                SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                interior_wall_particle.vs�  uniform mat4 MatrixPVW;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_POS;
varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;

	PS_TEXCOORD_LIFE.xyz = TEXCOORD0_LIFE.xyz;
	PS_COLOUR = DIFFUSE;
	PS_COLOUR.rgb *= PS_COLOUR.a;
}    interior_wall_particle.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[4];

varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

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


void main()
{
	vec4 colour = texture2D( SAMPLER[0], PS_TEXCOORD_LIFE.xy );
	gl_FragColor = vec4( colour.rgb * PS_COLOUR.rgb, colour.a * PS_COLOUR.a );
	gl_FragColor.rgb *= CalculateLightingContribution();
}                    