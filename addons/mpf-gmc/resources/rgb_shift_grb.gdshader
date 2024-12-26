shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	vec4 original_color = texture(SCREEN_TEXTURE, UV);
	COLOR.rgb = original_color.grb;
}
