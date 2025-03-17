uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_POS;
varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

const float TILE_SCALE = 4.0;

void main()
{
	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	PS_POS.xyz = world_pos.xyz;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD_LIFE.xyz = TEXCOORD0_LIFE.xyz;
	PS_COLOUR = DIFFUSE;
	PS_COLOUR.rgb *= PS_COLOUR.a;
}