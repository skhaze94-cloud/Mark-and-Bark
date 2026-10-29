shader_type canvas_item;
render_mode unshaded;
void fragment() {
	float left = 1.0 - smoothstep(0.49, 0.83, UV.x);
	float top = 1.0 - smoothstep(0.06, 0.30, UV.y);
	float bottom = smoothstep(0.79, 1.0, UV.y);
	COLOR = vec4(0.045, 0.12, 0.14, max(left * 0.78, max(top * 0.68, bottom * 0.86)));
}
