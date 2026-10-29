shader_type canvas_item;
render_mode unshaded;
// Applied below CanvasLayer HUDs: painted detail stays sharp and all text stays ungraded.
uniform sampler2D world_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float glow_strength : hint_range(0.0, 0.15) = 0.07;
uniform float vignette_strength : hint_range(0.0, 0.3) = 0.12;
uniform vec3 warmth = vec3(1.018, 1.008, 0.983);
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 source = texture(world_texture, uv).rgb;
	vec2 pixel = SCREEN_PIXEL_SIZE * 3.0;
	vec3 halo = texture(world_texture, uv + vec2(pixel.x, 0.0)).rgb;
	halo += texture(world_texture, uv - vec2(pixel.x, 0.0)).rgb;
	halo += texture(world_texture, uv + vec2(0.0, pixel.y)).rgb;
	halo += texture(world_texture, uv - vec2(0.0, pixel.y)).rgb;
	halo = max(halo * 0.25 - vec3(0.72), vec3(0.0));
	vec3 graded = ((source - 0.5) * 1.018 + 0.5) * warmth + halo * glow_strength;
	float edge = smoothstep(0.12, 0.48, dot(uv - 0.5, uv - 0.5));
	graded *= 1.0 - edge * vignette_strength;
	COLOR = vec4(clamp(graded, 0.0, 1.0), 1.0);
}
