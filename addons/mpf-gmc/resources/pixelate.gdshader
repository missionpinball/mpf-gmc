
// Shader to pixelate the screen texture

shader_type canvas_item;

uniform float columns = 128;
uniform float rows = 32;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
void fragment()
{
	float grid_u = round(UV.x * columns) / columns;
	float grid_v = round(UV.y * rows) / rows;
	vec4 text = texture(SCREEN_TEXTURE, vec2(grid_u, grid_v));
	COLOR = text;
}