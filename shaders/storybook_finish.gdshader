shader_type canvas_item;
render_mode unshaded;
uniform sampler2D world_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float glow_strength : hint_range(0.0, 0.15) = 0.065;
uniform float vignette_strength : hint_range(0.0, 0.3) = 0.13;
void fragment() {
 vec2 uv = SCREEN_UV;
 vec3 source = texture(world_texture, uv).rgb;
 vec2 step_uv = SCREEN_PIXEL_SIZE * 3.0;
 vec3 halo = texture(world_texture, uv + vec2(step_uv.x, 0.0)).rgb;
 halo += texture(world_texture, uv - vec2(step_uv.x, 0.0)).rgb;
 halo += texture(world_texture, uv + vec2(0.0, step_uv.y)).rgb;
 halo += texture(world_texture, uv - vec2(0.0, step_uv.y)).rgb;
 halo = max(halo * 0.25 - vec3(0.70), vec3(0.0));
 vec3 graded = source * vec3(1.016, 1.006, 0.985) + halo * glow_strength;
 float edge = smoothstep(0.10, 0.45, dot(uv - 0.5, uv - 0.5));
 graded *= 1.0 - edge * vignette_strength;
 COLOR = vec4(clamp(graded, 0.0, 1.0), 1.0);
}
