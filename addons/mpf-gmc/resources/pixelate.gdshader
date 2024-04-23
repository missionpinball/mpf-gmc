
// Shader to pixelate the screen texture

shader_type canvas_item;

uniform int columns = 128;
uniform int rows = 32;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
void fragment()
{
    float grid_u = round(UV.x * float(columns)) / float(columns);
    float grid_v = round(UV.y * float(rows)) / float(rows);
	vec4 text = texture(SCREEN_TEXTURE, vec2(grid_u, grid_v));
	COLOR = text;
}