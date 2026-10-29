extends Node2D
## Small paper creatures and light, anchored to the room rather than the screen.
## One canvas, no particles/nodes spawned as the camera explores the world.
const LIGHT = preload("res://scripts/painted_lighting.gd")
const CELL = Vector2(340.0, 270.0)
const MAX_DECORATIONS = 48
var context: String = "climb"
var level: int = 0
var tutorial: bool = false
var top: float = -8000.0
var time: float = 0.0
var paused: bool = false
var reduced_motion: bool = false
var controller: Node
var _last_frame: Rect2
var _last_still: bool = false

func _process(delta: float) -> void:
	reduced_motion = bool(Progress.settings.reduced_motion)
	paused = false
	if is_instance_valid(controller):
		if context == "menu":
			paused = is_instance_valid(controller.get("settings_overlay")) or controller.get("closing") == true
		else:
			paused = controller.get("busy") == true
	var still: bool = paused or reduced_motion
	if not still:
		time += minf(delta, 0.1)
	var frame: Rect2 = frame_rect()
	if not still or frame != _last_frame or reduced_motion != _last_still:
		queue_redraw()
	_last_frame = frame
	_last_still = reduced_motion

func frame_rect() -> Rect2:
	return get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()

func visible_decorations() -> Array:
	var entries: Array = []
	var frame: Rect2 = frame_rect().grow(45.0)
	var first_x: int = maxi(0, int(floor(frame.position.x / CELL.x)))
	var last_x: int = mini(4 if context == "climb" else 3 if context == "menu" else 16, int(floor(frame.end.x / CELL.x)))
	var first_y: int = maxi(int(floor((top if context == "climb" else 40.0) / CELL.y)), int(floor(frame.position.y / CELL.y)))
	var last_y: int = mini(1, int(floor(frame.end.y / CELL.y)))
	for row in range(first_y, last_y + 1):
		for column in range(first_x, last_x + 1):
			var key: int = posmod(row * 97 + column * 53 + level * 31, 997)
			var at: Vector2 = Vector2(column * CELL.x + 65 + posmod(key * 17, 210), row * CELL.y + 56 + posmod(key * 23, 150))
			if not frame.has_point(at):
				continue
			# Sparse side accents leave the central climb and menu text quiet.
			if context == "climb" and column == 2 and posmod(row, 3) != 0:
				continue
			if context == "menu" and at.x < 790.0:
				continue
			var theme: int = level
			if context == "menu" or (context == "story" and tutorial):
				theme = 1
			elif context == "story":
				theme = 0 if at.x < 1700.0 else 1 if at.x < 3700.0 else 2
			entries.append({"id": str(column) + ":" + str(row), "anchor": at, "kind": posmod(key, 3), "phase": float(key) * 0.17, "scale": 0.70 + float(posmod(key, 7)) * 0.075, "theme": theme})
			if entries.size() >= MAX_DECORATIONS:
				return entries
	return entries

func _draw() -> void:
	for entry in visible_decorations():
		var phase: float = float(entry.phase)
		var clock: float = 0.0 if reduced_motion else time
		var drift: Vector2 = Vector2(sin(clock * 0.34 + phase) * 12.0, sin(clock * 0.52 + phase) * 7.0)
		if reduced_motion:
			drift = Vector2.ZERO
		var at: Vector2 = entry.anchor + drift
		var size: float = float(entry.scale)
		var theme: int = int(entry.theme)
		var ink: Color = Color("fff2c9") if theme == 0 else Color("f7dfe8") if theme == 1 else Color("f7d997")
		ink.a = 0.66 if entry.kind == 0 else 0.46
		if context == "climb" and at.x > 370.0 and at.x < 1220.0:
			ink.a *= 0.60
		if context == "menu":
			ink.a *= 0.74
		if entry.kind == 0:
			_paper_moth(at, size, clock, phase, ink, theme)
		elif entry.kind == 1:
			LIGHT.glow(self, at, Vector2.ONE * 19.0 * size, Color(ink.r, ink.g, ink.b, ink.a * 0.17))
			_star(at, 4.2 * size, ink)
			_star(at + Vector2(19, -11) * size, 1.8 * size, Color(ink.r, ink.g, ink.b, ink.a * 0.55))
		else:
			_petal(at, size, ink, phase + clock * 0.18)

func _paper_moth(at: Vector2, size: float, clock: float, phase: float, ink: Color, theme: int) -> void:
	var wing: float = 0.76 if reduced_motion else 0.76 + sin(clock * 2.3 + phase) * 0.20
	LIGHT.glow(self, at, Vector2(26, 18) * size, Color(ink.r, ink.g, ink.b, ink.a * 0.13))
	for side in [-1.0, 1.0]:
		var tip: Vector2 = Vector2(side * 13.0 * wing, -8.0) * size
		var bottom: Vector2 = Vector2(side * 7.0 * wing, 5.0) * size
		var paper: Color = ink
		paper.a *= 0.80 if side < 0 else 1.0
		draw_colored_polygon(PackedVector2Array([at, at + tip, at + bottom]), paper)
		draw_line(at, at + tip, Color(0.41, 0.47, 0.48, ink.a * 0.30), 0.8, true)
	if theme == 0:
		# Book-paper folds; no collectible outline or interaction marker.
		draw_line(at + Vector2(-6, -1) * size, at + Vector2(-9 * wing, -4) * size, Color(0.48, 0.48, 0.39, ink.a * 0.35), 0.8, true)
	draw_line(at + Vector2(0, -2) * size, at + Vector2(0, 5) * size, Color(0.41, 0.47, 0.44, ink.a * 0.70), 1.0, true)
	# A tiny dotted wake stays close to the ornament, behind gameplay.
	for dot in range(3):
		var dust: Color = ink
		dust.a *= 0.27 - float(dot) * 0.06
		draw_circle(at + Vector2(-20 - dot * 9, 4 + dot * 3) * size, 1.1 * size, dust)

func _star(at: Vector2, radius: float, ink: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(8):
		var angle: float = float(n) * PI / 4.0
		var reach: float = radius if n % 2 == 0 else radius * 0.24
		points.append(at + Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(points, ink)

func _petal(at: Vector2, size: float, ink: Color, angle: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(20):
		var theta: float = float(n) * TAU / 20.0
		points.append(at + Vector2(cos(theta) * 5.5, sin(theta) * 2.8).rotated(angle) * size)
	draw_colored_polygon(points, ink)
	draw_line(at - Vector2(3.5, 0).rotated(angle) * size, at + Vector2(3.5, 0).rotated(angle) * size, Color(0.45, 0.52, 0.45, ink.a * 0.28), 0.8, true)
