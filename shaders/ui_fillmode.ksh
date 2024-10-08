   ui_fillmode   	   MatrixPVW                                                                                SAMPLER    +         IMAGE_PARAMS                                ui_fillmode.vsc  uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
	PS_COLOUR.rgba = vec4( DIFFUSE.rgb * DIFFUSE.a, DIFFUSE.a ); // premultiply the alpha
}    ui_fillmode.ps�  #if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

uniform vec2 ALPHA_RANGE; // SetAlphaRange
uniform vec4 IMAGE_PARAMS; // SetEffectParams
uniform vec4 IMAGE_PARAMS2; // SetEffectParams2

#define EXTRA_REPEAT_X       IMAGE_PARAMS.x
#define EXTRA_REPEAT_Y       IMAGE_PARAMS.y

void main()
{
    float tex_x = mod(PS_TEXCOORD.x * (1.0 + EXTRA_REPEAT_X), 1.0);
    float tex_y = mod(PS_TEXCOORD.y * (1.0 + EXTRA_REPEAT_Y), 1.0);

    vec2 new_texcoord = vec2(tex_x, tex_y);

    vec4 colour = texture2D( SAMPLER[0], new_texcoord.xy );
	colour.rgba *= PS_COLOUR.rgba;
      
	gl_FragColor = colour;
}                 