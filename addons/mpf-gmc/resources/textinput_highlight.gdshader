shader_type canvas_item;
uniform vec3 highlight_color: source_color = vec3(1.0, 0.0, 0.0);

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, highlight_color, abs(sin(TIME * 2.0)));
}

