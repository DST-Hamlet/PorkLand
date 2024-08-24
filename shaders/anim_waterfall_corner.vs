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

const float INDEX_SIZE = 9.0; // 预留的顶点数据数量

vec3 WaterfallOffset[int(INDEX_SIZE)];

float UVOffset[int(INDEX_SIZE)];

void init() // 猪咪手算顶点核心科技
{
	WaterfallOffset[0] = vec3(0.0, 0., 0.); // 0
    WaterfallOffset[1] = vec3(1.28, 0., 0.); // 1.28
    WaterfallOffset[2] = vec3(1.768, -0.196, 0.); // 0.5259
	WaterfallOffset[3] = vec3(2.184, -0.748, 0.); // 0.173056 + 0.304704 = 0.6912 ^ 2
    WaterfallOffset[4] = vec3(2.536, -2.06, 0.); // 0.123904 + 1.721344 = 1.3584 ^ 2
    WaterfallOffset[5] = vec3(2.56, -5.56, 0.); // 0.000576 + 12.25 = 3.5001 ^ 2
	WaterfallOffset[6] = vec3(2.56, -10.56, 0.); // 5
    WaterfallOffset[7] = vec3(2.56, -15.56, 0.); // 5
    WaterfallOffset[8] = vec3(2.56, -20.56, 0.); // 5

	UVOffset[0] = 0.0; // scale
	UVOffset[1] = 1.706667; // 0.75
	UVOffset[2] = 2.325373; // 0.85
	UVOffset[3] = 3.016573; // 1
	UVOffset[4] = 4.103293; // 1.25
	UVOffset[5] = 6.436693; // 1.5
	UVOffset[6] = 8.936693; // 2
	UVOffset[7] = 11.436693; // 2
	UVOffset[6] = 13.936693; // 2
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

    vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	vec3 origin = vec3(X, 0, Z);
	vec3 offset = world_pos.xyz - origin;
	int waterfall_index = int(offset.x * 0.25 + 0.1); // 根据顶点位置得到对应的顶点序号
	float old_x = offset.x;
	offset += WaterfallOffset[waterfall_index];
	offset -= vec3(old_x, 0., 0.);

	float offset_rotation = R;
	int corner_index = int(offset.z * 0.25 + 0.1);
	offset_rotation += float(corner_index) * 22.5 * 0.01745329252;
	mat3 rot = mat3(
    	cos(offset_rotation), 0.0, sin(offset_rotation),
    	0.0, 1.0, 0.0,
    	sin(offset_rotation), 0.0, -cos(offset_rotation));
	offset.z = 0.;

	vec3 offset_trans_3 = offset * rot;
	world_pos.xyz = offset_trans_3 + origin;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD = TEXCOORD0;
	PS_TEXCOORD.x = UVOffset[waterfall_index] * 0.15 * 0.25; // 纹理缩放，以及传递纹理坐标数据
	PS_TEXCOORD.y = float(corner_index) * 0.125 + 0.5;
	PS_POS = world_pos.xyz;

}