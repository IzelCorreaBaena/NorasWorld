shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.745, 0.745, 0.745, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float diff = distance(col.rgb, bg_color.rgb);
	if (diff < threshold) {
		col.a = 0.0;
	}
	COLOR = col;
}
