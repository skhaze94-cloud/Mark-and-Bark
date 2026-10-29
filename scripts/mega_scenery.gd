extends Node2D

# Decoration only. Every position is a world coordinate; the camera selects
# drawing work, never the position of a wall, light, shadow or piece of furniture.
const BAY_HEIGHT: float = 760.0
const BAY_ORIGIN: float = 650.0
var level: int = 0
var top: float = -8000.0
var visible_bay: int = 100000
var reduced_motion: bool = false
var motes
var _styles: Dictionary = {}

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	motes = load("res://scripts/mega_dust.gd").new()
	add_child(motes)

func _process(_delta: float) -> void:
	motes.reduced_motion = reduced_motion
	motes.top = top
	var game = get_parent().get_parent()
	motes.paused = game.get("busy") == true
	var camera = game.get("camera")
	if is_instance_valid(camera):
		var bay: int = int(floor((camera.position.y - BAY_ORIGIN) / BAY_HEIGHT)) + 1
		if bay != visible_bay:
			visible_bay = bay
			queue_redraw()

func box(rect: Rect2, color: String, radius: int = 8, shadow: bool = true) -> void:
	var key: String = color + ":" + str(radius) + ":" + str(shadow)
	if not _styles.has(key):
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(color)
		style.border_color = Color(color).darkened(0.24)
		style.set_border_width_all(2)
		style.set_corner_radius_all(radius)
		if shadow:
			style.shadow_color = Color(0.12, 0.16, 0.16, 0.16)
			style.shadow_size = 9
			style.shadow_offset = Vector2(7, 10)
		_styles[key] = style
	draw_style_box(_styles[key], rect)

func sprite(id: String, foot: Vector2, width: float, alpha: float = 1.0, cast: bool = true, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = Art.tex(id)
	var scale_factor: float = width / maxf(texture.get_width(), texture.get_height())
	var size: Vector2 = texture.get_size() * scale_factor
	var pivot: Array = Art.index.get(id, {}).get("pivot", [texture.get_width() / 2.0, texture.get_height()])
	var rect: Rect2 = Rect2(foot - Vector2(float(pivot[0]), float(pivot[1])) * scale_factor, size)
	if cast:
		# Several low-opacity offsets soften the painted silhouette on the wall.
		for step in range(3, -1, -1):
			draw_texture_rect(texture, Rect2(rect.position + Vector2(7 + step * 2, 9 + step * 2), rect.size), false, Color(0.09, 0.13, 0.15, 0.025 * alpha))
	var ink: Color = tint
	ink.a *= alpha
	draw_texture_rect(texture, rect, false, ink)

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(40):
		var angle: float = float(n) * TAU / 40.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _contact(foot: Vector2, width: float, opacity: float = 0.14) -> void:
	for step in range(4, 0, -1):
		_ellipse(foot + Vector2(5, 5), Vector2(width + step * 5, 5 + step * 2), Color(0.12, 0.17, 0.17, opacity / 4.0))

func _glow(center: Vector2, radius: Vector2, color: Color) -> void:
	for step in range(8, 0, -1):
		var ink: Color = color
		ink.a = color.a / 8.0
		_ellipse(center, radius * (float(step) / 8.0), ink)

func _light_beam(origin: Vector2, width: float, reach: Vector2, cool: bool = false) -> void:
	var ink: Color = Color(0.75, 0.88, 0.95, 0.045) if cool else Color(1.0, 0.93, 0.70, 0.055)
	for spread in range(3):
		var extra: float = float(spread) * 18.0
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(-extra, 0), origin + Vector2(width + extra, 0),
			origin + reach + Vector2(width + 70 + extra, 0), origin + reach + Vector2(-70 - extra, 0)
		]), ink)

func window_at(x: float, y: float, cool: bool = false, curtains: bool = false) -> void:
	_glow(Vector2(x + 130, y + 115), Vector2(205, 220), Color(0.74, 0.88, 0.92, 0.14) if cool else Color(1.0, 0.92, 0.69, 0.18))
	box(Rect2(x - 9, y - 9, 278, 248), "8b846b", 16)
	box(Rect2(x, y, 260, 225), "e3d7b9", 12, false)
	box(Rect2(x + 14, y + 14, 232, 197), "9db9be" if cool else "b4c9bf", 6, false)
	# Distant foliage and sky stay softer than the objects in front.
	for n in range(5):
		_ellipse(Vector2(x + 34 + n * 48, y + 155 + sin(float(n) * 1.8) * 16), Vector2(55, 40), Color(0.79, 0.84, 0.73, 0.52))
	draw_rect(Rect2(x + 18, y + 18, 224, 73), Color(0.89, 0.94, 0.88, 0.20))
	draw_line(Vector2(x + 130, y + 15), Vector2(x + 130, y + 211), Color("eee4c9"), 9)
	draw_line(Vector2(x + 14, y + 117), Vector2(x + 246, y + 117), Color("eee4c9"), 9)
	draw_line(Vector2(x + 22, y + 23), Vector2(x + 90, y + 23), Color(1, 1, 0.93, 0.50), 3)
	box(Rect2(x - 20, y + 215, 300, 20), "bda577", 4)
	if curtains:
		for side in [0, 1]:
			var left: float = x - 33 if side == 0 else x + 232
			box(Rect2(left, y - 18, 60, 247), "698a89", 12)
			for fold in range(3):
				draw_line(Vector2(left + 12 + fold * 15, y - 6), Vector2(left + 8 + fold * 17, y + 211), Color(0.84, 0.91, 0.81, 0.18), 3)
		draw_line(Vector2(x - 44, y - 20), Vector2(x + 304, y - 20), Color("88714f"), 7)

func _picture(at: Vector2, kind: int, opacity: float = 0.65) -> void:
	box(Rect2(at, Vector2(174, 140)), "b19c76", 7)
	box(Rect2(at + Vector2(9, 9), Vector2(156, 122)), "dfdfc8", 2, false)
	var ink: Color = Color(0.32, 0.47, 0.46, opacity)
	if kind == 0:
		draw_line(at + Vector2(82, 113), at + Vector2(94, 31), ink, 3, true)
		for n in range(3):
			_ellipse(at + Vector2(72 + n * 6, 86 - n * 20), Vector2(19, 8), ink)
			_ellipse(at + Vector2(105 + n * 3, 75 - n * 20), Vector2(18, 7), ink)
	elif kind == 1:
		draw_arc(at + Vector2(87, 72), 31, 0, TAU, 32, ink, 2, true)
		draw_line(at + Vector2(35, 105), at + Vector2(139, 39), ink, 2, true)
		draw_line(at + Vector2(48, 31), at + Vector2(124, 111), ink, 2, true)
		draw_circle(at + Vector2(87, 72), 7, Color(0.77, 0.61, 0.32, opacity))
	else:
		draw_colored_polygon(PackedVector2Array([at + Vector2(35, 105), at + Vector2(77, 43), at + Vector2(113, 105)]), ink)
		draw_colored_polygon(PackedVector2Array([at + Vector2(82, 105), at + Vector2(123, 65), at + Vector2(146, 105)]), Color(0.51, 0.61, 0.56, opacity))
		draw_circle(at + Vector2(120, 36), 12, Color(0.83, 0.69, 0.42, opacity))

func _zone(y: float) -> int:
	# top includes the existing 900px scenery overscan above the last shelf.
	var climb_height: float = maxf(1.0, 650.0 - (top + 900.0))
	return int(clampf((650.0 - y) / climb_height, 0.0, 0.999) * 3.0)

func _back_wall() -> void:
	var wall: Color = Color("ddd3b8") if level == 0 else Color("ccd3d0") if level == 1 else Color("b7afa3")
	draw_rect(Rect2(0, top, 1600, 900 - top), wall)
	# Broad value bands create a recessed back wall without a moving backdrop.
	for side in range(5):
		var opacity: float = float(5 - side) * 0.017
		draw_rect(Rect2(side * 34, top, 34, 900 - top), Color(0.22, 0.31, 0.31, opacity))
		draw_rect(Rect2(1566 - side * 34, top, 34, 900 - top), Color(0.22, 0.31, 0.31, opacity))
	draw_rect(Rect2(480, top, 640, 900 - top), Color(0.97, 0.96, 0.86, 0.07))

func _wall_bay(y: float, bay: int, zone: int) -> void:
	var shade: Color = Color(0.52, 0.57, 0.54, 0.035 + float(zone) * 0.014)
	draw_rect(Rect2(40, y - BAY_HEIGHT, 1520, BAY_HEIGHT), shade)
	# Off-center plaster washes are anchored and vary through negative bays.
	var drift: float = float(posmod(bay * 37, 110))
	_glow(Vector2(390 + drift, y - 370), Vector2(470, 360), Color(0.99, 0.95, 0.79, 0.075))
	_glow(Vector2(1320 - drift, y - 440), Vector2(300, 290), Color(0.60, 0.77, 0.82, 0.065))
	for x in [42, 1540]:
		draw_line(Vector2(x, y - BAY_HEIGHT), Vector2(x, y), Color(0.35, 0.39, 0.34, 0.12), 3)
	# The back wall retains a quiet painted surface all the way to the summit.
	# Native oak grain is used as a faint pigment texture rather than a flat fill.
	var grain_alpha: float = 0.085 if level == 2 else 0.065
	draw_texture_rect(Art.tex("oak_floor"), Rect2(50, y - BAY_HEIGHT, 1500, BAY_HEIGHT), true, Color(0.72, 0.74, 0.62, grain_alpha))
	if level == 0:
		_recess(Rect2(355, y - 710, 890, 625), "c7ccba" if zone < 2 else "c7d3c6", true)
	elif level == 1:
		_recess(Rect2(390, y - 700, 820, 590), "bec9c8" if zone < 2 else "c5ced5")
	else:
		_recess(Rect2(355, y - 700, 890, 600), "afafa5" if zone < 2 else "a8b5b5")
	# A second, lighter grain pass keeps recesses textured as well.
	draw_texture_rect(Art.tex("oak_floor"), Rect2(385, y - 675, 830, 550), true, Color(0.74, 0.77, 0.66, 0.048))
	for n in range(8):
		var mark_y: float = y - 55 - n * 89
		var mark_x: float = 160.0 + float(posmod(bay * 43 + n * 109, 1160))
		draw_line(Vector2(mark_x, mark_y), Vector2(mark_x + 92 + n * 7, mark_y - 2), Color(0.37, 0.46, 0.41, 0.035), 2, true)
	# Small side mouldings never imply a new walkable shelf across the route.
	for x in [45, 1175]:
		box(Rect2(x, y - 9, 380, 17), "aa9976" if level != 2 else "90764f", 3)

func _shelf(x: float, y: float, width: float, color: String = "9d835b") -> void:
	box(Rect2(x, y, width, 17), color, 4)
	for support_x in [x + 20, x + width - 27]:
		draw_line(Vector2(support_x, y + 17), Vector2(support_x + 10, y + 42), Color("877455"), 6, true)

func _bookcase(foot: Vector2, size: float, alpha: float = 0.78) -> void:
	var width: float = size * 1.04
	box(Rect2(foot - Vector2(width * 0.52, size + 18), Vector2(width, size + 27)), "a79774", 12)
	box(Rect2(foot - Vector2(width * 0.48, size), Vector2(width * 0.96, size - 9)), "7f897b", 6, false)
	_contact(foot, size * 0.38, 0.10)
	sprite("school_props_bookcase", foot, size, alpha)
	draw_line(foot + Vector2(-width * 0.49, -size - 9), foot + Vector2(width * 0.49, -size - 9), Color(0.99, 0.92, 0.71, 0.40), 3)

func _recess(rect: Rect2, color: String, arched: bool = false) -> void:
	var key: String = "recess:" + color + ":" + str(arched)
	if not _styles.has(key):
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(color)
		style.border_color = Color(color).darkened(0.085)
		style.set_border_width_all(3)
		style.corner_radius_top_left = 130 if arched else 18
		style.corner_radius_top_right = 130 if arched else 18
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0.20, 0.28, 0.27, 0.085)
		style.shadow_size = 18
		style.shadow_offset = Vector2(9, 12)
		_styles[key] = style
	draw_style_box(_styles[key], rect)
	draw_line(rect.position + Vector2(24, rect.size.y - 14), rect.end - Vector2(24, 14), Color(0.97, 0.94, 0.79, 0.26), 3, true)

func _drawer_stack(rect: Rect2) -> void:
	# A painted linen chest anchors the bedroom's smaller illustrated objects.
	box(rect, "a6a284", 12)
	var drawer_height: float = (rect.size.y - 26.0) / 3.0
	for n in range(3):
		var drawer: Rect2 = Rect2(rect.position + Vector2(12, 12 + n * drawer_height), Vector2(rect.size.x - 24, drawer_height - 7))
		box(drawer, "b9b69a" if n % 2 == 0 else "afb296", 6, false)
		for side in [0.30, 0.70]:
			var knob: Vector2 = drawer.position + Vector2(drawer.size.x * side, drawer.size.y * 0.5)
			draw_circle(knob + Vector2(1, 2), 5, Color(0.29, 0.34, 0.29, 0.17))
			draw_circle(knob, 4, Color("dfce9b"))
	draw_line(rect.position + Vector2(10, 5), rect.position + Vector2(rect.size.x - 10, 5), Color("d3ceb0"), 4, true)
	draw_rect(rect.grow(9), Color(0.76, 0.81, 0.73, 0.14))

func _library_backdrop(y: float, bay: int, zone: int) -> void:
	var motif: int = posmod(bay + zone, 4)
	var alpha: float = 0.49 if bay == 0 else 0.58
	var tint: Color = Color(0.93, 0.96, 0.87)
	if motif == 0 or motif == 2:
		var offset: float = -35.0 if motif == 0 else 45.0
		sprite("reading_nook_v3", Vector2(800 + offset, y - 135), 795 if zone == 0 else 750, alpha, true, tint)
		sprite("collectibles_books", Vector2(1120 + offset, y - 140), 145, alpha + 0.06, true, tint)
		if motif == 2:
			sprite("school_props_plant", Vector2(470, y - 142), 150, alpha, true, tint)
	else:
		var case_x: float = 705.0 if motif == 1 else 875.0
		sprite("school_props_bookcase", Vector2(case_x, y - 125), 565, alpha, true, tint)
		var desk_x: float = 1080.0 if motif == 1 else 485.0
		sprite("school_props_desk", Vector2(desk_x, y - 125), 305, alpha - 0.05, true, tint)
		sprite("school_props_lamp", Vector2(desk_x - 55, y - 323), 125, alpha + 0.05, true, tint)
		sprite("collectibles_books", Vector2(desk_x + 42, y - 323), 100, alpha, true, tint)
		sprite("school_props_chair", Vector2(desk_x + 110, y - 120), 190, alpha - 0.08, true, tint)
		_glow(Vector2(desk_x - 60, y - 408), Vector2(150, 135), Color(1.0, 0.91, 0.65, 0.10))
	# Tall panel joints and a tiny framed plate read as built architecture,
	# breaking the plain wall above the furniture without covering a route edge.
	for x in [375, 1225]:
		draw_line(Vector2(x, y - 650), Vector2(x, y - 115), Color(0.45, 0.49, 0.39, 0.14), 5, true)
		draw_line(Vector2(x + 5, y - 644), Vector2(x + 5, y - 120), Color(0.98, 0.94, 0.77, 0.27), 2, true)

func _bedroom_backdrop(y: float, bay: int, zone: int) -> void:
	var motif: int = posmod(bay + zone, 3)
	var tint: Color = Color(0.87, 0.95, 0.88)
	var alpha: float = 0.43 if bay == 0 else 0.55
	if motif == 0:
		sprite("reading_nook_v3", Vector2(790, y - 145), 775, alpha, true, tint)
		sprite("school_props_plant", Vector2(1110, y - 140), 180, alpha + 0.07, true, tint)
		sprite("collectibles_books", Vector2(485, y - 140), 135, alpha + 0.02, true, tint)
	elif motif == 1:
		_drawer_stack(Rect2(445, y - 430, 475, 280))
		sprite("school_props_plant", Vector2(820, y - 432), 175, alpha + 0.05, true, tint)
		sprite("collectibles_books", Vector2(575, y - 432), 150, alpha + 0.08, true, tint)
		sprite("school_props_bookcase", Vector2(1115, y - 145), 330, alpha, true, tint)
		_picture(Vector2(560, y - 650), 0, 0.39)
	else:
		_wardrobe(Rect2(430, y - 655, 305, 510), 0.55)
		sprite("school_props_desk", Vector2(1005, y - 145), 380, alpha, true, tint)
		sprite("school_props_lamp", Vector2(925, y - 392), 145, alpha + 0.05, true, tint)
		sprite("collectibles_books", Vector2(1050, y - 392), 135, alpha + 0.07, true, tint)
		sprite("school_props_chair", Vector2(1140, y - 140), 220, alpha - 0.04, true, tint)
		_glow(Vector2(915, y - 480), Vector2(145, 150), Color(1.0, 0.92, 0.69, 0.095))
	# Short, low-contrast linen panels connect the clusters into one room.
	for n in range(4):
		var x: float = 415 + n * 195
		draw_line(Vector2(x, y - 130), Vector2(x, y - 25), Color(0.39, 0.52, 0.46, 0.12), 3, true)
	draw_line(Vector2(420, y - 25), Vector2(1180, y - 25), Color(0.95, 0.96, 0.84, 0.24), 3, true)

func _attic_backdrop(y: float, bay: int, zone: int) -> void:
	var motif: int = posmod(bay + zone, 4)
	var tint: Color = Color(0.92, 0.92, 0.79)
	var alpha: float = 0.44 if bay == 0 else 0.57
	if motif == 2:
		sprite("school_props_bookcase", Vector2(875, y - 125), 545, alpha - 0.02, true, tint)
		sprite("school_props_desk", Vector2(485, y - 118), 350, alpha - 0.07, true, tint)
		sprite("school_props_lamp", Vector2(425, y - 345), 130, alpha, true, tint)
		sprite("collectibles_books", Vector2(540, y - 345), 105, alpha, true, tint)
	else:
		var desk_x: float = 815.0 + (55 if motif == 1 else -45 if motif == 3 else 0)
		sprite("school_props_desk", Vector2(desk_x, y - 115), 595, alpha, true, tint)
		# Native desktop artwork is 65% of the displayed width above its foot.
		sprite("school_props_lamp", Vector2(desk_x - 155, y - 502), 165, alpha + 0.07, true, tint)
		sprite("collectibles_books", Vector2(desk_x + 65, y - 502), 175, alpha + 0.05, true, tint)
		sprite("collectibles_envelope", Vector2(desk_x + 190, y - 502), 115, alpha, true, tint)
		sprite("school_props_chair", Vector2(desk_x + 260, y - 110), 265, alpha - 0.06, true, tint)
		_glow(Vector2(desk_x - 165, y - 600), Vector2(170, 150), Color(1.0, 0.88, 0.59, 0.12))
		if motif == 1:
			sprite("school_props_bookcase", Vector2(455, y - 120), 290, alpha - 0.07, true, tint)
	# Dusty crossbeams and their pale worn edges give the full-height back wall
	# the same timber language as the nearer side rafters.
	draw_line(Vector2(325, y - 715), Vector2(1275, y - 715), Color(0.39, 0.39, 0.30, 0.15), 19, true)
	draw_line(Vector2(325, y - 721), Vector2(1275, y - 721), Color(0.89, 0.82, 0.62, 0.30), 3, true)
	for x in [405, 1195]:
		draw_line(Vector2(x + 5, y - 704), Vector2(x + 5, y - 20), Color(0.28, 0.33, 0.29, 0.08), 20, true)
		draw_line(Vector2(x, y - 704), Vector2(x, y - 20), Color(0.54, 0.52, 0.39, 0.18), 14, true)
		draw_line(Vector2(x - 4, y - 700), Vector2(x - 4, y - 25), Color(0.92, 0.85, 0.65, 0.25), 2, true)

func _library_bay(y: float, bay: int, zone: int) -> void:
	_library_backdrop(y, bay, zone)
	var motif: int = posmod(bay, 4)
	if zone == 0:
		_bookcase(Vector2(224, y - 40), 360)
		if motif == 0 or motif == 3:
			window_at(1190, y - 650)
			_light_beam(Vector2(1212, y - 620), 180, Vector2(-250, 510))
			_shelf(1195, y - 55, 330)
			sprite("collectibles_books", Vector2(1295, y - 55), 130, 0.86)
			sprite("school_props_plant", Vector2(1450, y - 55), 120, 0.90)
		else:
			_bookcase(Vector2(1375, y - 35), 390, 0.77)
			_picture(Vector2(1150, y - 655), 0)
	elif zone == 1:
		# Tall, quiet stacks give the middle archive a different silhouette.
		_bookcase(Vector2(180, y - 40), 405, 0.72)
		_bookcase(Vector2(1390, y - 82), 350, 0.69)
		_shelf(1170, y - 490, 335)
		sprite("collectibles_books", Vector2(1280, y - 490), 155, 0.73)
		sprite("school_props_lamp", Vector2(1450, y - 490), 115, 0.87)
		_glow(Vector2(1435, y - 550), Vector2(170, 140), Color(1.0, 0.87, 0.56, 0.17))
	else:
		# The roof library opens into pale windows and lower, lighter stacks.
		var window_x: float = 100.0 if motif % 2 == 0 else 1220.0
		window_at(window_x, y - 650, true)
		_light_beam(Vector2(window_x + 24, y - 620), 175, Vector2(160 if window_x < 800 else -250, 560), true)
		var case_x: float = 1370.0 if window_x < 800 else 210.0
		_bookcase(Vector2(case_x, y - 45), 330, 0.70)
		sprite("school_props_plant", Vector2(window_x + 105, y - 415), 100, 0.83)
		_picture(Vector2(case_x - 88, y - 650), 2, 0.45)
		draw_line(Vector2(38, y - 720), Vector2(340, y - 620), Color(0.40, 0.37, 0.28, 0.17), 20, true)
		draw_line(Vector2(1562, y - 720), Vector2(1260, y - 620), Color(0.40, 0.37, 0.28, 0.17), 20, true)

func _wardrobe(rect: Rect2, alpha: float = 1.0) -> void:
	_contact(Vector2(rect.get_center().x, rect.end.y), rect.size.x * 0.39, 0.14 * alpha)
	box(rect, "8d795b", 14)
	box(Rect2(rect.position + Vector2(13, 21), Vector2(rect.size.x * 0.45, rect.size.y - 43)), "bea77a", 8, false)
	box(Rect2(rect.position + Vector2(rect.size.x * 0.52, 21), Vector2(rect.size.x * 0.44, rect.size.y - 43)), "ac9369", 8, false)
	draw_line(rect.position + Vector2(19, 10), rect.position + Vector2(rect.size.x - 19, 10), Color(0.98, 0.88, 0.63, 0.52 * alpha), 4)
	for side in [0.0, 1.0]:
		var x: float = rect.position.x + rect.size.x * (0.44 + side * 0.13)
		draw_circle(Vector2(x + 2, rect.get_center().y + 2), 6, Color(0.20, 0.23, 0.20, 0.25))
		draw_circle(Vector2(x, rect.get_center().y), 5, Color("e9cf8c"))
	if alpha < 1.0:
		draw_rect(rect.grow(10), Color(0.72, 0.78, 0.71, (1.0 - alpha) * 0.58))

func _bedroom_bay(y: float, bay: int, zone: int) -> void:
	_bedroom_backdrop(y, bay, zone)
	var motif: int = posmod(bay, 4)
	if zone == 0:
		_picture(Vector2(140, y - 660), 2)
		if motif % 2 == 0:
			window_at(1160, y - 655, false, true)
			_light_beam(Vector2(1185, y - 625), 175, Vector2(-280, 520))
		else:
			sprite("school_props_noticeboard", Vector2(1360, y - 430), 260, 0.65)
		if bay != 0:
			_shelf(80, y - 220, 300, "a58d6d")
			sprite("collectibles_books", Vector2(165, y - 220), 120, 0.81)
			sprite("collectibles_mug", Vector2(310, y - 220), 64, 0.80)
			_shelf(1215, y - 80, 290, "a58d6d")
			sprite("school_props_plant", Vector2(1420, y - 80), 145, 0.82)
	elif zone == 1:
		# Wardrobe trail: linen panels and drawers replace the toy-corner walls.
		if motif % 2 == 0:
			_wardrobe(Rect2(65, y - 620, 305, 560), 0.60)
			_picture(Vector2(1240, y - 615), 0, 0.48)
			_shelf(1180, y - 140, 340)
			sprite("collectibles_books", Vector2(1310, y - 140), 150, 0.73)
		else:
			_wardrobe(Rect2(1240, y - 620, 300, 550), 0.57)
			window_at(100, y - 625, true, true)
			_light_beam(Vector2(122, y - 594), 175, Vector2(200, 480), true)
		if motif == 1:
			_picture(Vector2(715, y - 640), 2, 0.28)
	else:
		# Window garden: open plaster, cool daylight and plants on the edges.
		var window_x: float = 100.0 if motif % 2 == 0 else 1200.0
		window_at(window_x, y - 650, true, true)
		_light_beam(Vector2(window_x + 22, y - 620), 180, Vector2(210 if window_x < 800 else -280, 560))
		var garden_x: float = 1260.0 if window_x < 800 else 110.0
		for n in range(3):
			draw_line(Vector2(garden_x + n * 80, y - 620), Vector2(garden_x + n * 80, y - 90), Color(0.43, 0.53, 0.44, 0.18), 4)
		_shelf(garden_x - 30, y - 90, 330, "a68c68")
		sprite("school_props_plant", Vector2(garden_x + 30, y - 90), 178, 0.83)
		sprite("school_props_plant", Vector2(garden_x + 220, y - 90), 125, 0.75)
		sprite("collectibles_mug", Vector2(window_x + 200, y - 415), 54, 0.85)
		if motif == 2:
			_picture(Vector2(695, y - 655), 0, 0.35)

func _rafter(start: Vector2, end: Vector2) -> void:
	draw_line(start + Vector2(9, 13), end + Vector2(9, 13), Color(0.19, 0.23, 0.22, 0.12), 35, true)
	draw_line(start, end, Color("796449"), 28, true)
	draw_line(start + Vector2(0, -6), end + Vector2(0, -6), Color("baa17b"), 3, true)
	for end_point in [start, end]:
		draw_circle(end_point, 5, Color("594e3d"))
		draw_circle(end_point + Vector2(-1, -1), 1.5, Color("d1bb8d"))

func _crate(at: Vector2, size: Vector2, faded: bool = false) -> void:
	_contact(at + Vector2(size.x * 0.5, size.y), size.x * 0.41, 0.10)
	box(Rect2(at, size), "a28b63" if faded else "ae8b55", 8)
	for n in range(1, 4):
		draw_line(at + Vector2(5, size.y * float(n) / 4.0), at + Vector2(size.x - 5, size.y * float(n) / 4.0), Color(0.37, 0.33, 0.25, 0.23), 2)
	draw_line(at + Vector2(17, 16), at + size - Vector2(17, 16), Color("d2b782"), 12, true)
	for nail in [Vector2(17, 16), size - Vector2(17, 16)]:
		draw_circle(at + nail, 2, Color("6b6049"))

func _spool(foot: Vector2, width: float, height: float) -> void:
	_contact(foot, width * 0.45)
	box(Rect2(foot.x - width * 0.37, foot.y - height, width * 0.74, height), "8c9d93", 7)
	for n in range(14):
		var y: float = foot.y - height + 11 + float(n) * (height - 22) / 14.0
		draw_line(Vector2(foot.x - width * 0.35, y), Vector2(foot.x + width * 0.35, y + 7), Color(0.83, 0.85, 0.68, 0.40), 3, true)
	_ellipse(foot + Vector2(0, -5), Vector2(width * 0.52, 17), Color("bba075"))
	_ellipse(foot + Vector2(0, -height), Vector2(width * 0.52, 20), Color("d3bb8d"))
	_ellipse(foot + Vector2(0, -height), Vector2(13, 6), Color("82755c"))

func _porthole(at: Vector2) -> void:
	_glow(at, Vector2(220, 220), Color(0.72, 0.87, 0.95, 0.16))
	draw_circle(at + Vector2(9, 10), 115, Color(0.19, 0.24, 0.24, 0.14))
	draw_circle(at, 112, Color("8d7959"))
	draw_circle(at, 101, Color("d7c49c"))
	draw_circle(at, 90, Color("8199ae"))
	for star_index in range(13):
		var angle: float = float(star_index) * 2.39996
		var radius: float = 19.0 + float(posmod(star_index * 19, 57))
		var dot: Vector2 = at + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(dot, 1.1 + float(star_index % 3) * 0.3, Color(0.98, 0.96, 0.80, 0.70))
	draw_circle(at + Vector2(24, -27), 24, Color("e6e4c2"))
	draw_circle(at + Vector2(34, -34), 22, Color("8199ae"))
	draw_arc(at, 82, 3.4, 5.3, 32, Color(0.94, 0.98, 0.91, 0.45), 3, true)
	draw_line(at + Vector2(0, -90), at + Vector2(0, 90), Color("d7c49c"), 7)
	draw_line(at + Vector2(-90, 0), at + Vector2(90, 0), Color("d7c49c"), 7)
	for n in range(8):
		var angle: float = float(n) * TAU / 8.0
		draw_circle(at + Vector2(cos(angle), sin(angle)) * 106, 3, Color("6e654f"))

func _attic_bay(y: float, bay: int, zone: int) -> void:
	_attic_backdrop(y, bay, zone)
	var motif: int = posmod(bay, 4)
	# Weathered boards stay in the sides; the climbing lane is a calm plaster wall.
	for x in [55, 1260]:
		draw_texture_rect(Art.tex("oak_floor"), Rect2(x, y - BAY_HEIGHT, 285, BAY_HEIGHT), true, Color(0.62, 0.59, 0.47, 0.12))
	_rafter(Vector2(-25, y - 720), Vector2(365, y - 470))
	_rafter(Vector2(1625, y - 720), Vector2(1250, y - 470))
	if zone == 0:
		_crate(Vector2(65, y - 225), Vector2(245, 180), true)
		if motif % 2 == 0:
			_crate(Vector2(100, y - 350), Vector2(180, 120), true)
		_shelf(1240, y - 110, 285)
		sprite("school_props_lamp", Vector2(1435, y - 110), 150, 0.88)
		sprite("collectibles_books", Vector2(1300, y - 110), 110, 0.77)
		_glow(Vector2(1425, y - 210), Vector2(205, 160), Color(1.0, 0.86, 0.53, 0.16))
		if motif == 2:
			sprite("school_props_noticeboard", Vector2(1240, y - 430), 225, 0.48, false)
	elif zone == 1:
		_spool(Vector2(190, y - 45), 190, 255)
		_spool(Vector2(340, y - 38), 115, 155)
		_crate(Vector2(1250, y - 225), Vector2(250, 180), true)
		sprite("collectibles_envelope", Vector2(1355, y - 225), 145, 0.74)
		if motif % 2 == 0:
			_picture(Vector2(1260, y - 640), 1, 0.45)
		else:
			_porthole(Vector2(1410, y - 570))
			_light_beam(Vector2(1345, y - 600), 125, Vector2(-290, 500), true)
	else:
		# Ray observatory: round sky openings and sparse diagrams, never a
		# second decorative copy of the collectible golden lens.
		var sky_x: float = 200.0 if motif % 2 == 0 else 1400.0
		_porthole(Vector2(sky_x, y - 555))
		_light_beam(Vector2(sky_x - 65, y - 585), 125, Vector2(260 if sky_x < 800 else -350, 540), true)
		var desk_x: float = 1260.0 if sky_x < 800 else 70.0
		_shelf(desk_x, y - 105, 285)
		sprite("school_props_lamp", Vector2(desk_x + 200, y - 105), 125, 0.72)
		sprite("collectibles_books", Vector2(desk_x + 65, y - 105), 110, 0.72)
		_picture(Vector2(desk_x + 55, y - 625), 1, 0.48)
		if motif == 3:
			draw_arc(Vector2(810, y - 550), 83, 0, TAU, 48, Color(0.40, 0.54, 0.54, 0.12), 2, true)
			draw_line(Vector2(710, y - 615), Vector2(905, y - 485), Color(0.40, 0.54, 0.54, 0.12), 2, true)

func _floor() -> void:
	box(Rect2(0, 625, 1600, 27), "a28a62", 2)
	draw_texture_rect(Art.tex("oak_floor"), Rect2(0, 650, 1600, 230), true, Color(0.91, 0.84, 0.69))
	draw_rect(Rect2(0, 650, 1600, 14), Color(0.18, 0.24, 0.23, 0.16))
	_glow(Vector2(790, 705), Vector2(620, 90), Color(1, 0.94, 0.73, 0.11))

func _bed() -> void:
	_contact(Vector2(285, 645), 218, 0.20)
	# A curved oak headboard belongs beside the painted furniture. Layered
	# pigment, inset moulding and asymmetrical grain give it a softer finish.
	var headboard: PackedVector2Array = PackedVector2Array()
	for n in range(33):
		var angle: float = PI + float(n) * PI / 32.0
		headboard.append(Vector2(270, 398) + Vector2(cos(angle) * 202, sin(angle) * 70))
	headboard.append(Vector2(472, 617))
	headboard.append(Vector2(68, 617))
	var cast: PackedVector2Array = PackedVector2Array()
	for point in headboard:
		cast.append(point + Vector2(8, 11))
	draw_colored_polygon(cast, Color(0.17, 0.21, 0.19, 0.17))
	draw_colored_polygon(headboard, Color("926b43"))
	draw_texture_rect(Art.tex("oak_floor"), Rect2(85, 389, 370, 218), true, Color(0.89, 0.73, 0.47, 0.42))
	# The inset follows the arched silhouette rather than reading as a flat box.
	var inset: PackedVector2Array = PackedVector2Array()
	for n in range(29):
		var angle: float = PI + float(n) * PI / 28.0
		inset.append(Vector2(270, 396) + Vector2(cos(angle) * 176, sin(angle) * 48))
	draw_polyline(inset, Color("d7b67f"), 5, true)
	draw_polyline(inset, Color(0.95, 0.83, 0.61, 0.38), 1.5, true)
	for x in [82, 454]:
		draw_line(Vector2(x + 5, 401), Vector2(x + 5, 612), Color(0.26, 0.22, 0.15, 0.27), 14, true)
		draw_line(Vector2(x, 397), Vector2(x, 612), Color("bc935b"), 11, true)
		draw_line(Vector2(x - 3, 401), Vector2(x - 3, 603), Color(0.98, 0.84, 0.60, 0.42), 2, true)
		draw_circle(Vector2(x, 387), 12, Color("83603c"))
		draw_circle(Vector2(x - 1, 384), 10, Color("d1b077"))
		draw_circle(Vector2(x - 4, 381), 3, Color(0.99, 0.90, 0.68, 0.62))
	for n in range(12):
		var grain_y: float = 378 + n * 15
		var grain: PackedVector2Array = PackedVector2Array()
		for step in range(9):
			grain.append(Vector2(108 + step * 38, grain_y + sin(float(step) * 1.1 + n) * 3))
		draw_polyline(grain, Color(0.34, 0.26, 0.16, 0.08), 1.4, true)
	box(Rect2(80, 420, 425, 180), "e5ddbc", 30)
	box(Rect2(87, 430, 410, 145), "eee7ce", 27, false)
	# Soft mattress welt and pillow creases replace the single flat cream slab.
	draw_line(Vector2(105, 584), Vector2(482, 584), Color(0.57, 0.52, 0.38, 0.34), 2, true)
	box(Rect2(92, 444, 126, 78), "d3cbb1", 25, false)
	box(Rect2(89, 437, 124, 74), "fff1d8", 25)
	for side in [-1, 1]:
		var crease: PackedVector2Array = PackedVector2Array()
		for n in range(13):
			var t: float = float(n) / 12.0
			crease.append(Vector2(151 + side * (31 + 15 * t), 447 + t * 47 + sin(t * PI) * 3))
		draw_polyline(crease, Color(0.64, 0.57, 0.41, 0.12), 2.5, true)
	box(Rect2(225, 434, 270, 166), "7897a6", 22)
	for n in range(7):
		var fold_x: float = 236 + n * 39
		var fold: PackedVector2Array = PackedVector2Array()
		for step in range(15):
			var t: float = float(step) / 14.0
			fold.append(Vector2(fold_x + sin(t * PI * 1.4 + n) * 4, 443 + t * 145))
		draw_polyline(fold, Color(0.28, 0.43, 0.49, 0.17), 7, true)
		draw_polyline(fold, Color(0.86, 0.89, 0.81, 0.31), 1.6, true)
	for n in range(4):
		var stitch: PackedVector2Array = PackedVector2Array()
		for step in range(29):
			var t: float = float(step) / 28.0
			stitch.append(Vector2(236 + t * 249, 454 + n * 34 + sin(t * PI * 4 + n) * 7))
		draw_polyline(stitch, Color(0.94, 0.88, 0.73, 0.24), 1.3, true)
	# A folded linen hem catches light and creates a thicker fabric edge.
	box(Rect2(228, 434, 265, 24), "a6b9b6", 11, false)
	draw_line(Vector2(238, 456), Vector2(483, 456), Color(0.28, 0.42, 0.45, 0.27), 2, true)
	for n in range(6):
		_star(Vector2(256 + n * 40, 478 + (n % 2) * 52), 8, Color(0.98, 0.91, 0.70, 0.70), 4)
	draw_line(Vector2(235, 586), Vector2(482, 586), Color("d5cfaf"), 3, true)
	for x in [95, 457]:
		box(Rect2(x, 607, 22, 43), "8c6840", 5)
		box(Rect2(x + 3, 614, 5, 30), "c09b63", 2, false)
	box(Rect2(76, 601, 432, 25), "9b7748", 7)
	draw_texture_rect(Art.tex("oak_floor"), Rect2(90, 607, 403, 12), true, Color(0.98, 0.82, 0.54, 0.32))
	draw_line(Vector2(88, 604), Vector2(494, 604), Color(0.99, 0.84, 0.59, 0.48), 2, true)

func _base_furniture() -> void:
	_floor()
	_story_rug()
	if level == 0:
		_contact(Vector2(228, 650), 235, 0.19)
		sprite("reading_nook_v3", Vector2(225, 650), 590)
		_contact(Vector2(1440, 650), 172, 0.19)
		sprite("school_props_bookcase", Vector2(1450, 650), 430)
		sprite("school_props_plant", Vector2(1190, 650), 165)
		sprite("school_props_noticeboard", Vector2(1045, 635), 185)
	elif level == 1:
		_bed()
		_wardrobe(Rect2(1150, 115, 355, 535))
		_contact(Vector2(850, 650), 173, 0.19)
		sprite("school_props_chair", Vector2(985, 650), 225)
		sprite("school_props_desk", Vector2(845, 650), 365)
		sprite("collectibles_mug", Vector2(890, 397), 54)
		_shelf(535, 318, 252)
		sprite("collectibles_books", Vector2(610, 318), 125)
		sprite("school_props_plant", Vector2(744, 318), 100)
		box(Rect2(1210, 537, 240, 113), "b08e59", 10)
		draw_line(Vector2(1218, 571), Vector2(1442, 571), Color("dbc08b"), 5)
		box(Rect2(1302, 577, 55, 16), "927b54", 5, false)
	else:
		_crate(Vector2(65, 440), Vector2(260, 210))
		_crate(Vector2(1230, 475), Vector2(285, 175))
		_contact(Vector2(820, 650), 205, 0.20)
		sprite("school_props_chair", Vector2(1050, 650), 240)
		sprite("school_props_desk", Vector2(810, 650), 420)
		sprite("school_props_science_volcano", Vector2(825, 377), 100)
		sprite("school_props_lamp", Vector2(700, 350), 140)
		sprite("collectibles_pencil", Vector2(1110, 650), 290)
		_glow(Vector2(697, 266), Vector2(170, 160), Color(1.0, 0.87, 0.58, 0.16))

func _edge_framing(y: float, bay: int) -> void:
	# Restrained near-edge silhouettes suggest a nearer layer while keeping the
	# active route and all of its pickups readable.
	var ink: Color = Color(0.21, 0.29, 0.29, 0.11) if level != 2 else Color(0.23, 0.24, 0.20, 0.15)
	draw_rect(Rect2(0, y - BAY_HEIGHT, 28, BAY_HEIGHT), ink)
	draw_rect(Rect2(1572, y - BAY_HEIGHT, 28, BAY_HEIGHT), ink)
	if posmod(bay, 3) == 1:
		var x: float = 15.0 if posmod(bay, 2) == 0 else 1585.0
		if level == 2:
			_rafter(Vector2(x, y - 720), Vector2(x + (55 if x < 800 else -55), y - 500))
		else:
			sprite("school_props_plant", Vector2(x, y - 18), 155, 0.42, false, Color("6f8275"))

# Whimsy is painted into the rooms. These ornaments never spawn physics,
# collectibles or input targets, and are deterministic at every world height.
func _leaf(at: Vector2, angle: float, length: float, ink: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var direction: Vector2 = Vector2(cos(angle), sin(angle))
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	for n in range(13):
		var t: float = float(n) / 12.0
		points.append(at + direction * length * t + normal * sin(t * PI) * length * 0.25)
	for n in range(12, -1, -1):
		var t: float = float(n) / 12.0
		points.append(at + direction * length * t - normal * sin(t * PI) * length * 0.25)
	draw_colored_polygon(points, ink)
	var vein: Color = ink.lightened(0.35)
	vein.a *= 0.55
	draw_line(at, at + direction * length * 0.86, vein, 1, true)

func _blossom(at: Vector2, radius: float, ink: Color) -> void:
	for petal in range(5):
		var angle: float = -PI * 0.5 + float(petal) * TAU / 5.0
		_ellipse(at + Vector2(cos(angle), sin(angle)) * radius * 0.49, Vector2(radius * 0.43, radius * 0.43), ink)
	draw_circle(at + Vector2(0.8, 1), radius * 0.21, Color(0.67, 0.49, 0.26, ink.a * 0.52))
	draw_circle(at, radius * 0.19, Color(0.98, 0.86, 0.53, ink.a))

func _star(at: Vector2, radius: float, ink: Color, tips: int = 5) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(tips * 2):
		var angle: float = -PI * 0.5 + float(n) * PI / float(tips)
		points.append(at + Vector2(cos(angle), sin(angle)) * radius * (1.0 if n % 2 == 0 else 0.42))
	draw_colored_polygon(points, ink)

func _vine(at: Vector2, length: float, bend: float, phase: float, flowers: bool = true, alpha: float = 0.62) -> void:
	var stem: PackedVector2Array = PackedVector2Array()
	for n in range(19):
		var t: float = float(n) / 18.0
		stem.append(at + Vector2(sin(t * PI * 1.8 + phase) * bend * t, t * length))
	draw_polyline(stem, Color(0.29, 0.46, 0.35, alpha * 0.72), 2.4, true)
	for n in range(1, 9):
		var t: float = float(n) / 9.0
		var point: Vector2 = at + Vector2(sin(t * PI * 1.8 + phase) * bend * t, t * length)
		var side: float = -1.0 if n % 2 == 0 else 1.0
		_leaf(point, -0.35 if side > 0 else PI + 0.35, 18 + float(n % 3) * 5, Color(0.39 + float(n % 2) * 0.07, 0.57, 0.43, alpha))
		if flowers and n % 3 == 0:
			_blossom(point + Vector2(side * 20, -1), 10, Color(0.93, 0.70, 0.64, alpha))

func _botanical_arch(y: float, bay: int, zone: int) -> void:
	# A fine garland follows the recessed arch, leaving the active shelf edges clear.
	var garland: PackedVector2Array = PackedVector2Array()
	for n in range(33):
		var t: float = float(n) / 32.0
		garland.append(Vector2(380 + t * 840, y - 609 - sin(t * PI) * 85))
	draw_polyline(garland, Color(0.45, 0.58, 0.42, 0.30), 3, true)
	for n in range(11):
		var t: float = (float(n) + 0.35) / 11.0
		var at: Vector2 = Vector2(380 + t * 840, y - 609 - sin(t * PI) * 85)
		_leaf(at, -0.7 if n % 2 == 0 else 0.8, 21 + float(n % 3) * 3, Color(0.47, 0.62, 0.45, 0.45))
		if n % 3 == posmod(bay, 3):
			_blossom(at + Vector2(4, 5), 8.5, Color(0.96, 0.77, 0.63, 0.62))
	_vine(Vector2(375, y - 620), 210 + zone * 25, 26, float(posmod(bay, 5)), true, 0.48)
	_vine(Vector2(1225, y - 620), 170 + zone * 35, -29, float(posmod(bay + 2, 5)), true, 0.48)

func _paper_bird(at: Vector2, size: float, ink: Color, facing: float = 1.0) -> void:
	# A little folded-paper swallow; deliberately unlike any gameplay pickup.
	var shadow: Vector2 = Vector2(4, 6)
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-0.54, 0.07), Vector2(-0.84, -0.46), Vector2(-0.08, -0.13),
		Vector2(0.14, -0.64), Vector2(0.34, -0.15), Vector2(0.72, -0.07),
		Vector2(0.31, 0.07), Vector2(0.12, 0.41), Vector2(-0.12, 0.12)
	])
	for n in range(outline.size()):
		outline[n] = at + outline[n] * Vector2(size * facing, size)
	var cast: PackedVector2Array = PackedVector2Array()
	for point in outline:
		cast.append(point + shadow)
	draw_colored_polygon(cast, Color(0.24, 0.34, 0.32, ink.a * 0.11))
	draw_colored_polygon(outline, ink)
	draw_line(at + Vector2(-0.55 * size * facing, 0.04 * size), at + Vector2(0.22 * size * facing, -0.08 * size), ink.darkened(0.18), 1.2, true)

func _cloud(at: Vector2, size: float, ink: Color) -> void:
	_ellipse(at + Vector2(-size * 0.34, 0), Vector2(size * 0.39, size * 0.19), ink)
	_ellipse(at + Vector2(size * 0.06, -size * 0.09), Vector2(size * 0.43, size * 0.28), ink)
	_ellipse(at + Vector2(size * 0.42, size * 0.015), Vector2(size * 0.34, size * 0.17), ink)

func _moon_mobile(at: Vector2, length: float, mirrored: bool = false) -> void:
	var direction: float = -1.0 if mirrored else 1.0
	var moon_at: Vector2 = at + Vector2(0, length)
	draw_line(at, moon_at + Vector2(0, -28), Color(0.46, 0.45, 0.50, 0.42), 1.5, true)
	# Construct a crescent directly so it remains transparent over every wall.
	var crescent: PackedVector2Array = PackedVector2Array()
	for n in range(31):
		var angle: float = -PI * 0.5 + float(n) * PI / 30.0
		crescent.append(moon_at + Vector2(cos(angle) * 31 * direction, sin(angle) * 31))
	for n in range(30, -1, -1):
		var angle: float = -PI * 0.5 + float(n) * PI / 30.0
		crescent.append(moon_at + Vector2(cos(angle) * 12 * direction, sin(angle) * 31))
	_glow(moon_at, Vector2(62, 62), Color(1.0, 0.90, 0.68, 0.08))
	draw_colored_polygon(crescent, Color(0.96, 0.88, 0.66, 0.87))
	for n in range(3):
		var star_at: Vector2 = moon_at + Vector2((40 + n * 24) * direction, -18 + (n % 2) * 38)
		draw_line(at + Vector2((40 + n * 24) * direction, 0), star_at - Vector2(0, 9), Color(0.48, 0.46, 0.54, 0.30), 1, true)
		_star(star_at, 9 + n % 2 * 3, Color(0.94, 0.85, 0.67, 0.70))

func _dream_mural(y: float, bay: int, zone: int) -> void:
	# Faded paint sits on the far wall, behind the original illustrated furniture.
	var drift: float = float(posmod(bay * 23, 80))
	_glow(Vector2(800, y - 520), Vector2(410, 180), Color(0.72, 0.73, 0.89, 0.13))
	_cloud(Vector2(640 + drift, y - 556), 150, Color(0.97, 0.94, 0.91, 0.19))
	_cloud(Vector2(974 - drift, y - 614), 112, Color(0.98, 0.94, 0.91, 0.18))
	for n in range(9):
		var at: Vector2 = Vector2(475 + float(posmod(n * 107 + bay * 31, 640)), y - 645 + float(posmod(n * 37, 165)))
		_star(at, 3.5 + n % 3, Color(0.97, 0.94, 0.79, 0.30), 4)

func _star_chart(at: Vector2, radius: float, phase: int, alpha: float = 0.32) -> void:
	var ink: Color = Color(0.42, 0.54, 0.59, alpha)
	var cream: Color = Color(0.95, 0.88, 0.67, alpha * 1.65)
	draw_arc(at, radius, 0, TAU, 64, ink, 1.6, true)
	draw_arc(at, radius * 0.86, 0, TAU, 64, ink, 1, true)
	for n in range(12):
		var angle: float = float(n) * TAU / 12.0
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(at + direction * radius * 0.91, at + direction * radius * (1.035 if n % 3 == 0 else 0.98), ink, 1.3, true)
	var path: PackedVector2Array = PackedVector2Array()
	for n in range(6):
		var point: Vector2 = at + Vector2(-0.65 + float(n) * 0.25, sin(float(n * 2 + phase)) * 0.45) * radius
		path.append(point)
		draw_circle(point, 2.7, cream)
	draw_polyline(path, ink, 1.2, true)
	_star(at + Vector2(radius * 0.23, -radius * 0.36), 8, cream, 4)

func _planet_mobile(at: Vector2, length: float, kind: int) -> void:
	var planet: Vector2 = at + Vector2(0, length)
	draw_line(at, planet - Vector2(0, 23), Color(0.38, 0.41, 0.42, 0.45), 1.4, true)
	_glow(planet, Vector2(67, 55), Color(0.94, 0.83, 0.62, 0.045))
	var ink: Color = Color("b6c4bc") if kind == 0 else Color("ccaa92")
	draw_circle(planet + Vector2(3, 4), 22, Color(0.24, 0.31, 0.31, 0.12))
	draw_circle(planet, 22, ink)
	draw_arc(planet + Vector2(-5, -3), 15, 3.4, 5.1, 20, ink.lightened(0.22), 3, true)
	var ring: PackedVector2Array = PackedVector2Array()
	for n in range(49):
		var angle: float = float(n) * TAU / 48.0
		ring.append(planet + Vector2(cos(angle) * 36, sin(angle) * 7).rotated(-0.32))
	draw_polyline(ring, Color(0.93, 0.83, 0.61, 0.64), 2, true)

func _whimsy_wall(y: float, bay: int, zone: int) -> void:
	# Wall paintings sit behind the furniture, not over its illustrated faces.
	if level == 0:
		_botanical_arch(y, bay, zone)
	elif level == 1:
		_dream_mural(y, bay, zone)
	else:
		var chart_x: float = 685.0 if posmod(bay, 2) == 0 else 920.0
		_star_chart(Vector2(chart_x, y - 525), 125 + zone * 9, posmod(bay, 7), 0.21)

func _whimsy_bay(y: float, bay: int, zone: int) -> void:
	if level == 0:
		var perch: Vector2 = Vector2(1430, y - 585) if posmod(bay, 2) == 0 else Vector2(195, y - 545)
		_paper_bird(perch, 35, Color(0.95, 0.89, 0.72, 0.79), -1 if perch.x > 800 else 1)
		if posmod(bay, 3) == 0:
			# An illustrated pressed-flower plate, far from collectible routes.
			var plate: Vector2 = Vector2(160, y - 620)
			_ellipse(plate, Vector2(47, 62), Color(0.91, 0.88, 0.71, 0.43))
			draw_arc(plate, 49, 0, TAU, 40, Color(0.67, 0.64, 0.44, 0.28), 1.5, true)
			_leaf(plate + Vector2(0, 27), -1.5, 45, Color(0.41, 0.57, 0.43, 0.54))
			_blossom(plate + Vector2(3, -10), 15, Color(0.85, 0.63, 0.60, 0.70))
	elif level == 1:
		var side_x: float = 155.0 if posmod(bay, 2) == 0 else 1400.0
		_moon_mobile(Vector2(side_x, y - 717), 103 + zone * 16, side_x > 800)
		# Trailing blossoms soften the window edge without covering its pane.
		var ribbon_x: float = 1460.0 if side_x < 800 else 105.0
		_vine(Vector2(ribbon_x, y - 690), 165, 13, 0.2, true, 0.31)
		if posmod(bay, 3) == 1:
			_paper_bird(Vector2(1325, y - 345), 27, Color(0.92, 0.80, 0.78, 0.65), -1)
	else:
		var mobile_x: float = 170.0 if posmod(bay, 2) == 0 else 1430.0
		_planet_mobile(Vector2(mobile_x, y - 706), 115 + zone * 12, posmod(bay, 2))
		if posmod(bay, 3) == 2:
			_paper_bird(Vector2(1390 if mobile_x < 800 else 215, y - 375), 40, Color(0.87, 0.86, 0.70, 0.72), -1 if mobile_x < 800 else 1)

func _base_whimsy() -> void:
	# These three floor discoveries sit below the HUD and beside the route.
	# The regular upper-bay mobiles remain subtle background details.
	if level == 0:
		_vine(Vector2(1358, 218), 180, 26, 0.6, true, 0.76)
		_paper_bird(Vector2(1382, 215), 38, Color(0.98, 0.88, 0.69, 0.90), -1)
	elif level == 1:
		_moon_mobile(Vector2(337, 168), 103, false)
		_cloud(Vector2(277, 284), 49, Color(0.96, 0.92, 0.90, 0.47))
	else:
		_planet_mobile(Vector2(365, 171), 132, 0)
		_star_chart(Vector2(364, 406), 43, 2, 0.36)

func _story_rug() -> void:
	# The flattened ellipse belongs to the real floor and suggests no new ledge.
	var ink: Color = Color(0.54, 0.64, 0.53, 0.36) if level == 0 else Color(0.63, 0.61, 0.70, 0.34) if level == 1 else Color(0.57, 0.63, 0.64, 0.31)
	_ellipse(Vector2(805, 716), Vector2(425, 62), Color(0.21, 0.30, 0.29, 0.09))
	_ellipse(Vector2(800, 706), Vector2(425, 62), ink)
	_ellipse(Vector2(800, 706), Vector2(406, 53), Color(0.97, 0.89, 0.69, 0.27))
	_ellipse(Vector2(800, 706), Vector2(391, 46), ink)
	for n in range(15):
		var angle: float = float(n) * TAU / 15.0
		var at: Vector2 = Vector2(800, 706) + Vector2(cos(angle) * 365, sin(angle) * 38)
		_ellipse(at, Vector2(5, 2), Color(0.96, 0.89, 0.70, 0.38))

func _draw() -> void:
	_back_wall()
	var center: int = 0 if visible_bay == 100000 else visible_bay
	# Five 760px bays cover the view plus generous fixed overscan. Drawing cost
	# stays bounded even when a climb grows taller or a checkpoint teleports.
	for bay in range(center - 2, center + 3):
		var y: float = BAY_ORIGIN + float(bay) * BAY_HEIGHT
		if y < top or y - BAY_HEIGHT > 650:
			continue
		var zone: int = _zone(y)
		_wall_bay(y, bay, zone)
		_whimsy_wall(y, bay, zone)
		if level == 0:
			_library_bay(y, bay, zone)
		elif level == 1:
			_bedroom_bay(y, bay, zone)
		else:
			_attic_bay(y, bay, zone)
		_whimsy_bay(y, bay, zone)
		_edge_framing(y, bay)
	if center >= -2 and center <= 1:
		_base_furniture()
		_base_whimsy()
