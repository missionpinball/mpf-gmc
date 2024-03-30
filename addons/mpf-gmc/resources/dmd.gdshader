shader_type canvas_item;

uniform float dot_columns = 64.0; // dots size | using int is ok
uniform vec4 color : source_color = vec4(0,0,0,1);
uniform float display_width = 1280.0;
uniform float display_height = 720.0;
uniform float hardness = 8.0;

void fragment() {
	//vec2 ratio = vec2(1.0, TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y); // make sure the dots are going to be 1:1
	vec2 ratio = vec2(1.0, display_height/display_width);
    float dots = length(fract(UV * dot_columns * ratio) - vec2(0.5)) * 2.0; // fracts the UV to make it loop, substract it by half then turn it into circle (using length) and finally multiply with 2 for smaller circle
	dots = (1.0 - dots) * hardness; // invert the dot then make it look hard so soft circle is no more
	dots = 1.0 - dots;
    dots = clamp(dots, 0.0, 1.0); // limit the value to 1.0, otherwise it would add your pixel's brightness instead of being a border (this is because some of it's value is above 1.0)
	//COLOR = mix(color, texture(TEXTURE, pixelated_uv), dots); // mix the dots with the texture
    COLOR.a = dots;
    COLOR.rgb = color.rgb;
}