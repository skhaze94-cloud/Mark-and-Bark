shader_type canvas_item;
render_mode unshaded;
// A light frame gives depth without dimming the playable centre or the HUD.
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float edge = smoothstep(0.45, 1.38, length(p * vec2(0.78, 0.85)));
 COLOR = vec4(0.075, 0.115, 0.12, edge * 0.22);
}
