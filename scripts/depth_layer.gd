extends Node2D

# Painted geometry complements the supplied raster art. All coordinates are
# world coordinates, so the playable floor and contact shadows stay aligned.
var foreground: bool = false
var tutorial: bool = false
var time: float = 0.0
var reduced_motion: bool = false
var camera_x: float = 640.0
var bursts: Array[Dictionary] = []

func _process(delta: float) -> void:
	time += delta
	for effect in bursts: effect.age += delta
	bursts = bursts.filter(func(e): return e.age < 0.8)
	queue_redraw()

func burst(at: Vector2) -> void:
	bursts.append({"pos": at, "age": 0.0})

func box(rect: Rect2, color: Color, radius: float = 8.0) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	draw_style_box(style, rect)

func plant(at: Vector2, size: float, shade: Color) -> void:
	var texture = Art.tex("school_props_plant")
	var height = size * 1.8
	var width = height * texture.get_width() / texture.get_height()
	var sway = 0.0 if reduced_motion else sin(time*0.8+at.x)*0.015
	draw_set_transform(at,sway)
	draw_texture_rect(texture,Rect2(-width/2,-height,width,height),false,Color(0.76,0.85,0.70,0.94))
	draw_set_transform(Vector2.ZERO)

func paint_ellipse(at: Vector2, radius: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(32): points.append(at + Vector2(cos(i * TAU / 32), sin(i * TAU / 32)) * radius)
	draw_colored_polygon(points, color)

func doorway(x: float, title: String, outside: bool = false) -> void:
	var texture = Art.tex("school_door_v2")
	var factor = 390.0/texture.get_height()
	draw_texture_rect(texture,Rect2(x-texture.get_width()*factor/2,610-1480*factor,texture.get_width()*factor,390),false)
	var panel = Art.tex("ui_parts_wood_button")
	draw_texture_rect(panel,Rect2(x-112,195,224,50),false)
	draw_string(Art.font,Vector2(x-99,225),title,HORIZONTAL_ALIGNMENT_CENTER,198,17,Color("fff0c8"))

func _draw() -> void:
	if foreground:
		# Only frame the edges: interaction targets and safe landing areas remain clear.
		for spec in [[1750.0, 92.0],[3650.0, 100.0],[2690.0, 58.0]]:
			plant(Vector2(spec[0], 704), spec[1], Color("415d45"))
		if tutorial:
			plant(Vector2(45,705),100,Color("415d45"))
			plant(Vector2(1500,705),100,Color("415d45"))
		return
	if tutorial:
		garden(0,1550)
	else:
		interior(0,1700,false)
		garden(1700,2000)
		interior(3700,1900,true)
	# Ambient specks have deterministic positions, no random flicker.
	if not reduced_motion:
		for i in range(52):
			var x = fmod(i * 113.7 + sin(time * 0.17 + i) * 18, 5600)
			var y = 185 + fmod(i * 47.3 + time * 5, 370)
			draw_circle(Vector2(x,y), 1.5 + (i % 2), Color(1,0.93,0.70,0.24))
	for e in bursts:
		for i in range(9):
			var radius = 22.0 if reduced_motion else 16 + e.age * 95
			var p: Vector2 = e.pos + Vector2(cos(i*TAU/9),sin(i*TAU/9)) * radius
			draw_circle(p,3,Color(1,0.86,0.40,1-e.age/0.8))

func interior(start: float, span: float, workshop: bool) -> void:
	# The supplied painting already has walls and windows. Add light and floor
	# perspective without covering its rich detail with opaque vector stand-ins.
	for i in range(int(span/115)+1):
		var x = start+i*115.0
		draw_line(Vector2(x,610),Vector2(x+(x-start-span/2)*0.16,720),Color(0.16,0.13,0.11,0.20),2)
	for y in [631,667,714]: draw_line(Vector2(start,y),Vector2(start+span,y),Color(0.17,0.14,0.12,0.14),2)
	for local_x in ([span*0.76] if not workshop else [span*0.15,span*0.65]):
		var x: float = start + local_x
		draw_polygon(PackedVector2Array([Vector2(x,180),Vector2(x+140,180),Vector2(x+420,610),Vector2(x+170,610)]),PackedColorArray([Color(1,0.91,0.62,0.06)]))
	if not workshop:
		doorway(start+65,"School entrance",true)
		doorway(start+span-65,"Garden →",true)
	else:
		doorway(start+65,"← Garden",true)

func garden(start: float, span: float) -> void:
	# Distant oak silhouettes move more slowly than the foreground.
	var offset = 0.0
	for i in range(6):
		var x = start + 90 + i * span/5 + offset
		draw_line(Vector2(x,560),Vector2(x-18,235),Color(0.30,0.39,0.26,0.18),23)
		paint_ellipse(Vector2(x,230),Vector2(155,115),Color(0.26,0.42,0.30,0.12))
	# Bridge decking over a decorative stream below the safe walkway.
	draw_texture_rect(Art.tex("garden_soil"),Rect2(start,626,span,94),true,Color(0.76,0.79,0.67))
	# The painted backdrop already contains its bridge and stream; keep its detail.
	draw_rect(Rect2(start,626,span,12),Color(0.18,0.27,0.18,0.16))
	draw_line(Vector2(start,617),Vector2(start+span,617),Color("ddc389"),5)
	for i in range(8):
		var at = Vector2(start+130+i*span/8,670)
		paint_ellipse(at,Vector2(28,5),Color(0.2,0.25,0.15,0.15))
	if not tutorial:
		doorway(start+65,"← School",false)
		doorway(start+span-65,"Workshop →",false)
		# A textured little sign marks the elevated secret, leaving the painting intact.
		draw_texture_rect(Art.tex("ui_parts_wood_button"),Rect2(start+1000,252,170,70),false)
		draw_string(Art.font,Vector2(start+1012,281),"BARK'S",HORIZONTAL_ALIGNMENT_CENTER,146,15,Color("f9e6b2"))
		draw_string(Art.font,Vector2(start+1012,304),"SECRET NOOK",HORIZONTAL_ALIGNMENT_CENTER,146,13,Color("f9e6b2"))
	if not reduced_motion:
		for i in range(4):
			var at = Vector2(start+350+i*span/5+sin(time*0.55+i)*48,330+cos(time*0.8+i)*32)
			var flap = absf(sin(time*6+i))
			paint_ellipse(at+Vector2(-4,0),Vector2(2+flap*4,4),Color(1,0.91,0.61,0.60))
			paint_ellipse(at+Vector2(4,0),Vector2(2+flap*4,4),Color(1,0.91,0.61,0.60))
