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
	var wall: Color = Color("d8cbae") if level == 0 else Color("c2cfc4") if level == 1 else Color("b6a58d")
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

func _library_bay(y: float, bay: int, zone: int) -> void:
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
		if motif == 2:
			_picture(Vector2(695, y - 625), 1, 0.35)
	elif zone == 1:
		# Tall, quiet stacks give the middle archive a different silhouette.
		_bookcase(Vector2(180, y - 40), 405, 0.72)
		_bookcase(Vector2(1390, y - 82), 350, 0.69)
		_shelf(1170, y - 490, 335)
		sprite("collectibles_books", Vector2(1280, y - 490), 155, 0.73)
		sprite("school_props_lamp", Vector2(1450, y - 490), 115, 0.87)
		_glow(Vector2(1435, y - 550), Vector2(170, 140), Color(1.0, 0.87, 0.56, 0.17))
		if motif == 1:
			sprite("school_props_bookcase", Vector2(805, y - 240), 390, 0.25, false, Color("a8b3a5"))
		elif motif == 3:
			sprite("school_props_noticeboard", Vector2(780, y - 330), 235, 0.39, false)
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
	draw_circle(at, 90, Color("9fb7bb"))
	draw_circle(at + Vector2(24, -27), 24, Color("e6e4c2"))
	draw_arc(at, 82, 3.4, 5.3, 32, Color(0.94, 0.98, 0.91, 0.45), 3, true)
	draw_line(at + Vector2(0, -90), at + Vector2(0, 90), Color("d7c49c"), 7)
	draw_line(at + Vector2(-90, 0), at + Vector2(90, 0), Color("d7c49c"), 7)
	for n in range(8):
		var angle: float = float(n) * TAU / 8.0
		draw_circle(at + Vector2(cos(angle), sin(angle)) * 106, 3, Color("6e654f"))

func _attic_bay(y: float, bay: int, zone: int) -> void:
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
	box(Rect2(63, 350, 410, 290), "8b7150", 21)
	box(Rect2(80, 420, 425, 180), "e9dfbe", 28)
	box(Rect2(90, 438, 120, 73), "fff2d7", 24)
	draw_arc(Vector2(148, 475), 38, 3.8, 5.5, 24, Color(0.72, 0.67, 0.53, 0.24), 2, true)
	box(Rect2(225, 434, 270, 166), "6c8c8c", 17)
	for x in range(244, 493, 35):
		draw_line(Vector2(x, 441), Vector2(x, 591), Color(0.77, 0.84, 0.72, 0.41), 2, true)
	for y in range(460, 590, 30):
		draw_line(Vector2(231, y), Vector2(488, y), Color(0.77, 0.84, 0.72, 0.35), 2, true)
	draw_line(Vector2(235, 581), Vector2(486, 581), Color("c4ceaf"), 3)
	for x in [95, 457]:
		box(Rect2(x, 607, 22, 43), "8b7150", 5)
	box(Rect2(76, 601, 432, 25), "a18355", 7)

func _base_furniture() -> void:
	_floor()
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
		if level == 0:
			_library_bay(y, bay, zone)
		elif level == 1:
			_bedroom_bay(y, bay, zone)
		else:
			_attic_bay(y, bay, zone)
		_edge_framing(y, bay)
	if center >= -2 and center <= 1:
		_base_furniture()
