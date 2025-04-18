   anim_waterfall      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                FLOAT_PARAMS                            SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                             
   TIMEPARAMS                                COLOUR_XFORM                                                                                PARAMS                        OCEAN_BLEND_PARAMS                                OCEAN_WORLD_EXTENTS                                anim_waterfall.vs
  uniform mat4 MatrixP;
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
	WaterfallOffset[0] = vec3(0., 0., 0.); // 0
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
	UVOffset[6] = 9.936693; // 2
	UVOffset[7] = 11.436693; // 2
	UVOffset[8] = 13.936693; // 2
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
	int waterfall_index = int(offset.x * 0.25 + 0.1); // 根据顶点位置得到对应的顶点序号
	float old_x = offset.x;
	offset += WaterfallOffset[waterfall_index];
	offset += vec3(- 1.5, 0., 0.);
	offset -= vec3(old_x, 0., 0.);
	
	vec3 offset_trans_3 = offset * rot;
	world_pos.xyz = offset_trans_3 + origin;

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD = TEXCOORD0;
	PS_TEXCOORD.x = UVOffset[waterfall_index] * 0.15; // 纹理缩放，以及传递纹理坐标数据
	PS_POS = world_pos.xyz;

}    anim_waterfall.pse  #if defined( GL_ES )
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
    vec4 colour; //基础纹理
    vec4 colour_2; //表层水流纹理

    float tex_x = PS_TEXCOORD.x * 0.25 - mod(TIMEPARAMS.x, 1.0) * 0.125 + 0.125; // 纹理平移
    float tex_x_2 = PS_TEXCOORD.x * 0.25 - mod(TIMEPARAMS.x, 2.0) * 0.0625 + 0.125; // 表层水流纹理平移，速度更慢
    float tex_y = PS_TEXCOORD.y;
    vec3 new_texcoord = vec3(tex_x, tex_y, PS_TEXCOORD.z);
    vec3 new_texcoord_2 = vec3(tex_x_2, tex_y, PS_TEXCOORD.z);

#if defined( TRIPLE_ATLAS )
    if( new_texcoord.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], new_texcoord.xy );
        colour_2.rgba = texture2D( SAMPLER[0], new_texcoord_2.xy );
    }
    else if( new_texcoord.z < 1.5 )
    {
        colour.rgba = texture2D( SAMPLER[1], new_texcoord.xy );
        colour_2.rgba = texture2D( SAMPLER[1], new_texcoord_2.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[5], new_texcoord.xy );
        colour_2.rgba = texture2D( SAMPLER[5], new_texcoord_2.xy );
    }
#else
    if( new_texcoord.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], new_texcoord.xy );
        colour_2.rgba = texture2D( SAMPLER[0], new_texcoord_2.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[1], new_texcoord.xy );
        colour_2.rgba = texture2D( SAMPLER[1], new_texcoord_2.xy );
    }
#endif

float alpha_val = 0.7; // 表层水流纹理透明度

if (colour_2.a < 0.95)
{
    alpha_val = 0.35; // 降低表层水流半透明部分的权重影响
}

colour.rgb = colour_2.rgb * alpha_val + colour.rgb * (1.0 - alpha_val) ;

if (colour.a < 0.95)
{
    colour.a = 1. + PS_POS.y * 0.5; // 世界坐标越低的纹理越偏白色
}

if (PS_POS.y < -2.)
{
    if (colour.a > 0.)
    {
        colour.a *= 1. + (2. + PS_POS.y) * 0.5; // 世界坐标越低的纹理越透明
    }
}

if (colour.a > 1.0)
{
    colour.a = 1.0;
}
if (colour.a < 0.0)
{
    colour.a = 0.0;
}

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

        if (PS_POS.y < -2.)
        {
            light.r *= 1. + (2. + PS_POS.y) * 0.5; // 减少低坐标透明纹理的光照贴图的透明度
            light.g *= 1. + (2. + PS_POS.y) * 0.5;
            light.b *= 1. + (2. + PS_POS.y) * 0.5;
        }

        gl_FragColor.rgb *= max( light.rgb, vec3( LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE ) );
    }
#if defined ( FADE_OUT )
	else
	{
		discard;
	}
#endif

}                                   	   
   