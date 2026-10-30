extends Control
## Three quiet essentials: discoveries, two real spring charges, and pause.
## Objectives and adventure tools live in the notebook/pause menu.
signal pause_requested
signal journal_requested
const BotanicalButton = preload("res://scripts/whimsy_hud_button.gd")
var controller: Node
var score: int = 0
var total: int = 24
var energy: int = 2
var max_energy: int = 2
var paused: bool = false
var reduced_motion: bool = false
var touch_enabled: bool = false
var can_use: bool = false
var score_button: Button
var pause_button: Button
var touch_root: Control
var touch_buttons: Dictionary = {}
# left, top, right, bottom in logical viewport pixels; useful on inset displays.
var safe_insets: Vector4 = Vector4.ZERO:
	set(value):
		safe_insets = value
		if is_node_ready():
			_layout()
var score_pulse: float = 0.0
var score_gain: int = 0
var score_key: String = ""
var _last_score_key: String = ""
var _energy_rect: Rect2
var _initialized: bool = false
var _leaf_icon: TextureRect
var _score_sparkles: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_button = Button.new()
	score_button.name = "LeafScore"
	score_button.focus_mode = Control.FOCUS_NONE
	score_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	score_button.add_theme_font_override("font", Art.font)
	score_button.add_theme_font_size_override("font_size", 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		score_button.add_theme_color_override(state, Color("fff2cf"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("284a50ee") if state != "hover" else Color("3c6264f5")
		style.border_color = Color("d8bc7b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(26)
		style.content_margin_left = 43
		style.content_margin_right = 13
		style.shadow_color = Color(0.05, 0.13, 0.14, 0.16)
		style.shadow_size = 3
		style.shadow_offset = Vector2(0, 2)
		score_button.add_theme_stylebox_override(state, style)
	add_child(score_button)
	score_button.pressed.connect(func(): journal_requested.emit())
	_leaf_icon = TextureRect.new()
	_leaf_icon.texture = Art.tex("collectibles_leaf_token")
	_leaf_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leaf_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_leaf_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leaf_icon.position = Vector2(10, 9)
	_leaf_icon.size = Vector2(33, 33)
	score_button.add_child(_leaf_icon)
	_score_sparkles = Control.new()
	_score_sparkles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_sparkles.size = Vector2(150, 52)
	_score_sparkles.draw.connect(_draw_score_sparkles)
	score_button.add_child(_score_sparkles)
	pause_button = _new_button("pause", self)
	pause_button.name = "HudPause"
	pause_button.tooltip_text = "Pause · notebook, Bark's hint, checkpoint and settings [Esc]"
	pause_button.pressed.connect(func(): pause_requested.emit())
	touch_root = Control.new()
	touch_root.name = "TouchControls"
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(touch_root)
	for action in ["left", "right", "jump", "use"]:
		var control = _new_button(action, touch_root)
		control.name = "Touch" + action.capitalize()
		control.tooltip_text = {"left": "Move left", "right": "Move right", "jump": "Jump · jump again for Bark's spring", "use": "Use the nearby object"}[action]
		touch_buttons[action] = control
	_read_mobile_insets()
	resized.connect(_on_resize)
	_layout()
	update_state(score, total, energy, touch_enabled, can_use)
	_initialized = false

func _new_button(kind: String, parent: Node) -> Button:
	var control = BotanicalButton.new()
	control.kind = kind
	parent.add_child(control)
	return control

func _read_mobile_insets() -> void:
	if not OS.has_feature("mobile"):
		return
	var window_size: Vector2i = DisplayServer.window_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if window_size.x <= 0 or window_size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return
	var ratio: Vector2 = size / Vector2(window_size)
	safe_insets = Vector4(maxf(0, safe.position.x * ratio.x), maxf(0, safe.position.y * ratio.y), maxf(0, (window_size.x - safe.end.x) * ratio.x), maxf(0, (window_size.y - safe.end.y) * ratio.y))

func _on_resize() -> void:
	_read_mobile_insets()
	_layout()

func _layout() -> void:
	if not is_instance_valid(score_button) or not is_instance_valid(touch_root):
		return
	var margin: float = 24.0 if size.x >= 1000 else 16.0
	var left: float = margin + safe_insets.x
	var right: float = size.x - margin - safe_insets.z
	var top: float = margin + safe_insets.y
	var bottom: float = size.y - 28.0 - safe_insets.w
	score_button.position = Vector2(left, top)
	score_button.size = Vector2(150, 52)
	pause_button.position = Vector2(right - 52, top)
	pause_button.size = Vector2(52, 52)
	_energy_rect = Rect2(left + 8, top + 58, 118, 22)
	touch_root.position = Vector2.ZERO
	touch_root.size = size
	var rectangles = {
		"left": Rect2(left, bottom - 72, 72, 72),
		"right": Rect2(left + 84, bottom - 72, 72, 72),
		"jump": Rect2(right - 88, bottom - 88, 88, 88),
		"use": Rect2(right - 180, bottom - 72, 72, 72)
	}
	for action in touch_buttons:
		touch_buttons[action].position = rectangles[action].position
		touch_buttons[action].size = rectangles[action].size
	queue_redraw()

func update_state(found: int, possible: int, leaps: int, show_touch: bool, usable: bool) -> void:
	var changed: bool = energy != clampi(leaps, 0, max_energy)
	if _last_score_key != score_key:
		score_pulse = 0
		if is_instance_valid(_score_sparkles):
			_score_sparkles.queue_redraw()
	if _initialized and _last_score_key == score_key and found > score and not reduced_motion:
		score_gain = found - score
		score_pulse = 0.65
	_last_score_key = score_key
	score = maxi(0, found)
	total = maxi(0, possible)
	energy = clampi(leaps, 0, max_energy)
	touch_enabled = show_touch
	can_use = usable
	if not is_node_ready():
		return
	score_button.text = str(score) + " / " + str(total)
	score_button.tooltip_text = "Leaves discovered · notebook [N]. Bark's spring: " + str(energy) + " of 2 leaps ready."
	score_button.disabled = paused
	pause_button.disabled = paused
	touch_root.visible = touch_enabled and not paused
	touch_buttons.use.visible = can_use
	for control in touch_buttons.values():
		control.disabled = paused
	tooltip_text = "Bark's spring: " + str(energy) + " of 2 leaps ready. Land to recharge."
	_initialized = true
	if changed:
		queue_redraw()

func _process(delta: float) -> void:
	var was_paused: bool = paused
	paused = is_instance_valid(controller) and controller.get("busy") == true
	reduced_motion = bool(Progress.settings.reduced_motion)
	if was_paused != paused:
		update_state(score, total, energy, touch_enabled, can_use)
	if reduced_motion and score_pulse > 0:
		score_pulse = 0
		_score_sparkles.queue_redraw()
	elif not paused and score_pulse > 0:
		score_pulse = maxf(0, score_pulse - delta)
		_score_sparkles.queue_redraw()

func touch_rect(action: String) -> Rect2:
	if not touch_buttons.has(action):
		return Rect2()
	return touch_buttons[action].get_global_rect()

func persistent_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not is_visible_in_tree():
		return result
	for control in [score_button, pause_button]:
		if is_instance_valid(control) and control.is_visible_in_tree():
			result.append(control.get_global_rect())
	result.append(Rect2(global_position + _energy_rect.position, _energy_rect.size))
	return result

func occupied_rects() -> Array[Rect2]:
	var result: Array[Rect2] = persistent_rects()
	for control in touch_buttons.values():
		if control.is_visible_in_tree():
			result.append(control.get_global_rect())
	return result

func idle_area() -> float:
	var result: float = 0.0
	for rect in persistent_rects():
		result += rect.get_area()
	return result

func _draw() -> void:
	if not is_node_ready():
		return
	var at: Vector2 = _energy_rect.position
	# A quiet ink wash keeps the little stems readable on light and dark scenery.
	var backing = StyleBoxFlat.new()
	backing.bg_color = Color("284a50bb")
	backing.set_corner_radius_all(11)
	draw_style_box(backing, _energy_rect)
	draw_line(at + Vector2(12, 13), at + Vector2(105, 13), Color("d4bd80"), 1, true)
	for n in range(max_energy):
		var center: Vector2 = at + Vector2(33 + n * 48, 10)
		var points: PackedVector2Array = PackedVector2Array()
		for side in [-1.0, 1.0]:
			for step in range(13):
				var t: float = float(step) / 12.0 if side < 0 else 1.0 - float(step) / 12.0
				points.append(center + Vector2((t - 0.5) * 29.0, sin(t * PI) * 6.0 * side).rotated(-0.26))
		points.append(points[0])
		var tint: Color = Color("b5d49d") if n < energy else Color("577879")
		draw_colored_polygon(points, tint)
		draw_polyline(points, Color("dfd3a0") if n < energy else Color("91a6a0"), 1, true)
		draw_line(center - Vector2(9, -2), center + Vector2(9, -2), Color("526e52") if n < energy else Color("8ba19c"), 0.8, true)
func _draw_score_sparkles() -> void:
	if score_pulse > 0:
		var strength: float = score_pulse / 0.65
		var origin: Vector2 = Vector2(27, 26)
		for n in range(4):
			var angle: float = float(n) * TAU / 4.0 + 0.25
			var point: Vector2 = origin + Vector2(cos(angle), sin(angle)) * (18.0 + (1.0 - strength) * 8.0)
			_score_sparkles.draw_circle(point, 1.5, Color(1, 0.87, 0.50, strength * 0.75))
		var chip = StyleBoxFlat.new()
		chip.bg_color = Color(0.72, 0.84, 0.64, strength)
		chip.set_corner_radius_all(10)
		_score_sparkles.draw_style_box(chip, Rect2(113, -7 - (1.0 - strength) * 6.0, 38, 22))
		_score_sparkles.draw_string(Art.font, Vector2(119, 9 - (1.0 - strength) * 6.0), "+" + str(score_gain), HORIZONTAL_ALIGNMENT_LEFT, 32, 15, Color(0.12, 0.25, 0.25, strength))
