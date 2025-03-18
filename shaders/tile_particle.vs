uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_POS;
varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;
varying vec2 PS_TEXCOORD_NOISE;

const float TILE_SCALE = 4.0;

void main()
{
	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	float start_x = floor(world_pos.x + 0.5);
	float start_z = floor(world_pos.z + 0.5);

	float tex_x = mod(start_x, 29.0) * 0.03446276 * 0.25 + 0.0390625;
	float tex_z = mod(start_z, 29.0) * 0.03446276 * 0.25 + 0.0390625;

    if( start_x > world_pos.x)
	{    
		world_pos.x = start_x - 2.0;
		tex_x -= 0.01723138;
	}
    else
    {
		world_pos.x = start_x + 2.0;
		tex_x += 0.01723138;
    }

	if( start_z > world_pos.z)
	{    
		world_pos.z = start_z - 2.0;
		tex_z -= 0.01723138;
	}
    else
    {
		world_pos.z = start_z + 2.0;
		tex_z += 0.01723138;
    }

	PS_POS.xyz = world_pos.xyz;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD_LIFE.xyz = TEXCOORD0_LIFE.xyz;
	PS_COLOUR = DIFFUSE;
	PS_COLOUR.rgb *= PS_COLOUR.a;
	PS_TEXCOORD_NOISE.xy = vec2(tex_x, tex_z);
}