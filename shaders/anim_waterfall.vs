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

const float INDEX_SIZE = 9.0;

vec3 WaterfallOffset[int(INDEX_SIZE)];

void init()
{
	WaterfallOffset[0] = vec3(0., 0., 0.);
    WaterfallOffset[1] = vec3(1., 0., 0.);
    WaterfallOffset[2] = vec3(1.9238, -0.3827, 0.);
	WaterfallOffset[3] = vec3(2.6309, -1.0898, 0.);
    WaterfallOffset[4] = vec3(3.0136, -2.0136, 0.);
    WaterfallOffset[5] = vec3(3.0136, -3.5136, 0.);
	WaterfallOffset[6] = vec3(3.0136, -6.0136, 0.);
    WaterfallOffset[7] = vec3(0., 0., 0.);
    WaterfallOffset[8] = vec3(0., 0., 0.);
}

void main()
{
	init();

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
	int waterfall_index = int(offset.x * 0.25 + 0.1);
	float old_x = offset.x;
	offset += WaterfallOffset[waterfall_index];
	offset -= vec3(old_x, 0., 0.);
	
	vec3 offset_trans_3 = offset;
	world_pos.xyz = offset_trans_3 + origin;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD = TEXCOORD0;
	PS_TEXCOORD.x = float(waterfall_index) * 0.25;
	PS_POS = world_pos.xyz;

}