extends Node2D
# All furniture and foliage stay anchored in world space. Depth comes from overlap and light.
var planes: Array[Dictionary] = []
var camera_x: float = 640.0
var reduced_motion: bool = false
var tutorial: bool = false
var time: float = 0.0
var light_sources: Array = []

func add_piece(id: String, at: Vector2, span: float, _depth: float, _center: float, layer: int, sway: float = 0.0) -> Sprite2D:
	var sprite = Art.prop(id,span)
	sprite.position=at
	sprite.z_index=layer
	var cast = Sprite2D.new()
	cast.texture=sprite.texture
	cast.centered=false
	cast.offset=sprite.offset
	cast.position=Vector2(9,6)
	cast.modulate=Color(0.09,0.13,0.13,0.20)
	cast.show_behind_parent=true
	sprite.add_child(cast)
	add_child(sprite)
	planes.append({"sprite":sprite,"origin":at,"sway":sway})
	return sprite

func build(is_tutorial: bool) -> void:
	tutorial=is_tutorial
	if not tutorial:
		add_piece("school_props_red_locker",Vector2(335,560),255,0.10,850,1)
		add_piece("school_props_navy_locker",Vector2(515,560),255,0.10,850,1)
		add_piece("reading_nook_v3",Vector2(1220,575),420,0.16,850,1)
		add_piece("school_props_bookcase",Vector2(5350,540),270,0.12,4650,1)
		add_piece("school_props_plant",Vector2(4930,510),105,0.17,4650,1,0.012)
		add_piece("school_props_plant",Vector2(960,408),83,0.18,850,1,0.014)
		for spec in [[65.0,850.0],[1635.0,850.0],[1740.0,2700.0],[3660.0,2700.0],[3750.0,4650.0],[5550.0,4650.0]]:
			add_piece("canopy_v3",Vector2(spec[0],265),340,-0.26,spec[1],14,0.008)
	else:
		add_piece("canopy_v3",Vector2(80,230),350,-0.24,775,14,0.008)
		add_piece("canopy_v3",Vector2(1500,230),350,-0.24,775,14,0.009)
	light_sources=[Vector2(410,230),Vector2(1210,220)] if tutorial else [Vector2(1300,205),Vector2(2250,240),Vector2(3050,190),Vector2(4110,190),Vector2(4980,180)]
	queue_redraw()

func _process(delta: float) -> void:
	time+=delta
	for piece in planes:
		var sprite: Sprite2D=piece.sprite
		sprite.position=piece.origin
		if not reduced_motion:
			sprite.rotation=sin(time*0.65+float(piece.origin.x))*float(piece.sway)
		else:sprite.rotation=0
	queue_redraw()

func _draw() -> void:
	for source in light_sources:
		var brightness=1.0 if reduced_motion else 0.97+sin(time*0.35+source.x)*0.03
		var pts=PackedVector2Array([source,source+Vector2(75,0),source+Vector2(330,405),source+Vector2(130,405)])
		draw_polygon(pts,PackedColorArray([Color(1,0.93,0.74,0.012),Color(1,0.93,0.74,0.018),Color(1,0.92,0.70,0.065*brightness),Color(1,0.92,0.70,0.015)]))
	if not reduced_motion:
		for source in light_sources:
			for i in range(11):
				var p=source+Vector2(20+i*17+sin(time*0.45+i)*7,80+fmod(i*27.2+time*8,300))
				draw_circle(p,1.2,Color(1,0.96,0.82,0.18))
