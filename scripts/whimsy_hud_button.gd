extends Button
## Small botanical controls, with real Button focus and hit testing.
var kind: String = "pause"

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", Art.font)
	add_theme_font_size_override("font_size", 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		add_theme_color_override(state, Color("fff2cf"))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var paper = StyleBoxFlat.new()
		paper.bg_color = Color("284a50e8")
		if state == "hover":
			paper.bg_color = Color("3c6264f5")
		elif state == "pressed":
			paper.bg_color = Color("193c42f5")
		elif state == "disabled":
			paper.bg_color.a = 0.25
		paper.border_color = Color("d8bc7b")
		paper.set_border_width_all(1)
		paper.set_corner_radius_all(40)
		paper.shadow_color = Color(0.05, 0.13, 0.14, 0.18)
		paper.shadow_size = 3
		paper.shadow_offset = Vector2(0, 2)
		add_theme_stylebox_override(state, paper)
	if kind == "jump":
		text = "Jump"
	elif kind == "use":
		text = "Use"

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var ink: Color = Color("fff2cf")
	if disabled:
		ink.a = 0.35
	if kind == "pause":
		for offset in [-4.5, 4.5]:
			draw_line(center + Vector2(offset, -8), center + Vector2(offset, 8), ink, 3, true)
	elif kind in ["left", "right"]:
		var side: float = -1.0 if kind == "left" else 1.0
		draw_polyline(PackedVector2Array([center + Vector2(-side * 5, -9), center + Vector2(side * 5, 0), center + Vector2(-side * 5, 9)]), ink, 3, true)
	# A tiny stitched sprig distinguishes the controls from generic glass buttons.
	var at: Vector2 = Vector2(size.x * 0.76, size.y * 0.15)
	draw_line(at + Vector2(-4, 5), at + Vector2(6, -2), Color("d5bd80"), 1, true)
	draw_colored_polygon(PackedVector2Array([at, at + Vector2(-4, -4), at + Vector2(-8, -3), at + Vector2(-4, 0)]), Color("a9c5a3"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(2, 1), at + Vector2(4, 5), at + Vector2(8, 5), at + Vector2(6, 1)]), Color("a9c5a3"))
