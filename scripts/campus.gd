extends Node2D

var objects: Array[Dictionary] = []
var width: float = 5600
var tutorial: bool = false
var clock: float = 0
var reduced_motion: bool = false
var board
var feedback
var scenery
var bark: Sprite2D
var platforms: Array[Rect2] = []
var fun_ledges: Array[Node2D] = []
var markers: Array[Node2D] = []
var depth
var foreground
var room: int = 0
var backgrounds: Array[Dictionary] = []
const ROOM_BOUNDS = [Vector2(0,1700),Vector2(1700,3700),Vector2(3700,5600)]
const ROOM_NAMES = ["SCHOOL HALLWAY","DISCOVERY GARDEN","CLASSROOM WORKSHOP"]

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR

func build(is_tutorial: bool) -> void:
	tutorial = is_tutorial
	width = 1550 if tutorial else 5600
	for child in get_children():
		remove_child(child)
		child.queue_free()
	objects.clear()
	platforms.clear()
	fun_ledges.clear()
	markers.clear()
	backgrounds.clear()
	if tutorial:
		background("garden_hub",0,1550)
	else:
		background("school_hub",0,1700)
		background("garden_hub",1700,2000)
		background("workshop_hub_v4",3700,1900)
	depth = load("res://scripts/depth_layer.gd").new()
	depth.tutorial = tutorial
	depth.z_index = 0
	add_child(depth)
	foreground = load("res://scripts/depth_layer.gd").new()
	foreground.tutorial = tutorial
	foreground.foreground = true
	foreground.z_index = 12
	add_child(foreground)
	scenery=load("res://scripts/scenery_planes.gd").new()
	add_child(scenery)
	scenery.build(tutorial)
	feedback=load("res://scripts/interaction_feedback.gd").new()
	feedback.campus=self
	feedback.z_index=6
	add_child(feedback)
	board=null
	if not tutorial:
		board=load("res://scripts/invention_board.gd").new()
		board.name="LiveInventionBoard"
		board.position=Vector2(4920,385)
		add_child(board)
	add_lights()
	var ground = StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 2
	var cs = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(width,120)
	cs.shape = rectangle
	cs.position = Vector2(width/2,670)
	ground.add_child(cs)
	add_child(ground)
	if tutorial:
		add_platform(Rect2(410,575,100,35),"school_props_log")
		add_platform(Rect2(555,385,185,20),"fun_book")
		add_object("tutorial_notebook","collectibles_notebook",Vector2(680,610),"Your notebook",100)
		add_object("tutorial_leaf","collectibles_leaf_token",Vector2(840,545),"A bright leaf",65)
		add_object("tutorial_plane","collectibles_paper_plane",Vector2(1080,590),"Practice plane",110)
		add_object("tutorial_target","ui_parts_reward_check",Vector2(1370,480),"Practice target",115)
		bark = Art.character("bark_actions_idle")
		bark.position = Vector2(320,610)
		bark.scale = Vector2.ONE*0.20
		add_child(bark)
	else:
		add_object("invitation","school_props_noticeboard",Vector2(810,600),"Big Ideas Fair invitation",215)
		add_object("notebook","collectibles_notebook",Vector2(2150,290),"Mark's scattered design",110)
		add_object("plant_bed","school_props_stump",Vector2(2320,610),"Garden display · return the plant",180)
		add_object("plant","school_props_plant",Vector2(2840,610),"The wandering plant",145)
		for rect in [Rect2(1990,550,180,20),Rect2(2225,490,175,20),Rect2(2470,430,190,20),Rect2(2730,430,190,20),Rect2(2980,430,190,20),Rect2(3220,490,180,20)]:
			add_platform(rect,"school_props_log")
		add_object("books","collectibles_books",Vector2(3290,190),"Book base",95)
		add_object("pencil","collectibles_pencil",Vector2(5310,260),"Pencil guide",110)
		add_object("doodle_1","collectibles_notebook",Vector2(2500,255),"Notebook discovery",70)
		add_object("doodle_2","collectibles_notebook",Vector2(5200,600),"Notebook discovery",70)
		add_object("bark_token","collectibles_bark_token",Vector2(2830,240),"Bark's secret token",75)
		# Leafy-lift routes carry essential supplies as well as optional discoveries.
		add_platform(Rect2(2060,290,190,20),"fun_book")
		add_platform(Rect2(3200,190,210,20),"fun_book")
		for rect in [Rect2(960,520,205,20),Rect2(1210,405,195,20),Rect2(1450,285,195,20)]:
			add_platform(rect,"fun_book")
		for rect in [Rect2(2400,255,200,20),Rect2(2740,250,205,20),Rect2(3035,240,210,20)]:
			add_platform(rect,"fun_leaf")
		for rect in [Rect2(4630,470,205,20),Rect2(4870,250,220,20),Rect2(5180,260,230,20)]:
			add_platform(rect,"fun_pencil" if rect.position.x==4870 else "fun_book")
		world_label("BOOK-SPINE SKYWAY",Vector2(1160,255),16)
		world_label("DESIGN: JUMP + LEAFY LIFT",Vector2(1900,410),16)
		world_label("BOOK BASE: UP IN THE BRANCHES",Vector2(3120,330),16)
		world_label("THE PENCIL EXPRESS",Vector2(4810,410),16)
		decorate("collectibles_books",Vector2(1160,610),230)
		decorate("collectibles_pencil",Vector2(5220,610),270)
		var leaf_positions = [Vector2(1545,270),Vector2(2090,525),Vector2(2390,600),Vector2(3135,225),Vector2(3850,540),Vector2(5310,245)]
		for i in range(6):
			add_object("leaf_"+str(i+1),"collectibles_leaf_token",leaf_positions[i],"Leaf discovery",55)
		add_object("shortcut","ui_parts_wood_button",Vector2(3630,610),"Garden shortcut to workshop",120)
		add_object("workshop","school_props_desk",Vector2(4430,610),"Mark & Bark's invention desk",310)
		add_object("fair_target","school_props_noticeboard",Vector2(5050,360),"The Big Ideas Fair target",205)
		add_object("volcano","school_props_science_volcano",Vector2(4020,610),"Bark's volcano inspection",185)
		decorate("school_props_lamp",Vector2(4310,460),100)
		bark = Art.character("bark_actions_idle")
		bark.scale = Vector2.ONE*0.20
		bark.position = Vector2(340,610)
		add_child(bark)
	bark.z_index = 3
	var bark_shadow=load("res://scripts/prop_shadow.gd").new()
	bark_shadow.source=bark
	bark_shadow.follows=true
	bark_shadow.half_width=18
	bark_shadow.softness=5
	bark_shadow.z_index=1
	add_child(bark_shadow)
	refresh()
	queue_redraw()

func background(id: String, x: float, span: float) -> void:
	var s = Sprite2D.new()
	s.texture = Art.tex(id)
	s.centered = false
	s.position = Vector2(x-span*0.0225,0 if id.begins_with("workshop_hub_") else -305)
	s.scale = Vector2(span*1.045/s.texture.get_width(),(720.0 if id.begins_with("workshop_hub_") else 915.0)/s.texture.get_height())
	s.z_index = -10
	add_child(s)
	backgrounds.append({"sprite":s,"base":s.position.x,"center":x+span/2})

func decorate(id: String, pos: Vector2, size: float) -> Sprite2D:
	var sprite = Art.prop(id,size)
	sprite.position = pos
	sprite.z_index = 2
	add_child(sprite)
	var shadow=load("res://scripts/prop_shadow.gd").new()
	shadow.source=sprite
	shadow.anchor=Vector2(pos.x,610 if pos.y>=585 else pos.y)
	shadow.half_width=size*0.38
	shadow.softness=clampf(size*0.035,3,10)
	shadow.z_index=1
	add_child(shadow)
	return sprite

func add_object(id: String, asset: String, pos: Vector2, title: String, size: float) -> void:
	var sprite = decorate(asset,pos,size)
	var label_node = world_label(title,pos+Vector2(-125,-size-34),16)
	label_node.modulate.a = 0.95
	objects.append({"id":id,"pos":pos,"sprite":sprite,"label":label_node,"title":title,"visible":true})

func world_label(text: String, pos: Vector2, size: int) -> Label:
	var l = Label.new()
	l.z_index = 5
	l.text = text
	l.position = pos
	l.size = Vector2(330,55)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font",Art.font)
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color("fff2cd"))
	l.add_theme_color_override("font_shadow_color",Color("162c3c"))
	l.add_theme_constant_override("shadow_offset_x",2)
	l.add_theme_constant_override("shadow_offset_y",2)
	add_child(l)
	return l

func add_platform(rect: Rect2, asset: String) -> void:
	platforms.append(rect)
	var body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	shape.one_way_collision = true
	shape.one_way_collision_margin = 8
	body.add_child(shape)
	add_child(body)
	if asset.begins_with("fun_"):
		var ledge=load("res://scripts/fun_platform.gd").new()
		ledge.position=rect.position
		ledge.width=rect.size.x
		ledge.kind=asset.trim_prefix("fun_")
		ledge.height=32 if ledge.kind=="pencil" else 44
		ledge.z_index=1
		add_child(ledge)
		fun_ledges.append(ledge)
		return
	# Align the top of each painted log with its collision top.
	var texture = Art.tex(asset)
	var painted_height = texture.get_height()*rect.size.x/texture.get_width()
	var s = decorate(asset,Vector2(rect.get_center().x,rect.position.y+painted_height),rect.size.x)
	s.z_index = -1

func object(id: String) -> Dictionary:
	for item in objects:
		if item.id==id:
			return item
	return {}

func refresh() -> void:
	for item in objects:
		var id: String = item.id
		var show = true
		if not tutorial:
			if id in ["notebook","plant","books","pencil"]:
				show = not bool(Progress.data[id])
			elif id.begins_with("leaf_"):
				show = not id in Progress.data.leaves
			elif id in ["doodle_1","doodle_2"]:
				show = not id in Progress.data.discoveries
			elif id=="bark_token":
				show = not bool(Progress.data.bark_token)
			elif id=="shortcut":
				show = bool(Progress.data.plant_restored)
		item.visible = show
		item.sprite.visible = show and id!="fair_target"
		item.label.visible = false # Contextual HUD prompts keep the scenery uncluttered.
	if not tutorial and bool(Progress.data.plant_restored):
		if not has_node("RestoredPlant"):
			var s = decorate("school_props_plant",Vector2(2320,555),95)
			s.name = "RestoredPlant"
	if not tutorial:
		for id in ["DeskBooks","DeskPencil","DeskPlane"]:
			if has_node(id):
				var old = get_node(id)
				remove_child(old)
				old.queue_free()
		if int(Progress.data.assembled)>=1:
			var s = decorate("collectibles_books",Vector2(4390,457),110)
			s.name="DeskBooks"
		if int(Progress.data.assembled)>=2:
			var s = decorate("collectibles_pencil",Vector2(4470,445),90)
			s.name="DeskPencil"
		if int(Progress.data.assembled)>=3:
			var s = decorate("collectibles_paper_plane",Vector2(4450,415),100)
			s.name="DeskPlane"

func nearest(pos: Vector2, range_px: float = 150) -> Dictionary:
	var found: Dictionary = {}
	var best = range_px
	for item in objects:
		if not item.visible or item.id.begins_with("leaf_") or item.id in ["tutorial_target","fair_target","tutorial_leaf"]:
			continue
		var d = absf(item.pos.x-pos.x)
		var reach_y = 70 if item.id in ["notebook","books","pencil"] else 145
		if d<best and absf(item.pos.y-pos.y)<reach_y:
			found=item
			best=d
	return found

func _process(delta: float) -> void:
	clock+=delta
	for ledge in fun_ledges:ledge.reduced_motion=reduced_motion
	if is_instance_valid(depth):
		depth.reduced_motion = reduced_motion
		foreground.reduced_motion = reduced_motion
		scenery.reduced_motion = reduced_motion
		for backdrop in backgrounds:
			backdrop.sprite.position.x = backdrop.base
	for item in objects:
		if item.id.begins_with("leaf_") or item.id in ["tutorial_leaf","bark_token"]:
			item.sprite.position.y = item.pos.y

func _draw() -> void:
	# Continuous ceiling above the workshop keeps rising camera views finished.
	if not tutorial:
		draw_texture_rect(Art.tex("oak_floor"),Rect2(3700,-450,1900,450),true,Color(0.46,0.40,0.31))
	var tile = Art.tex("garden_soil" if tutorial else "oak_floor")
	draw_texture_rect(tile,Rect2(0,610,width,110),true,Color(0.60,0.56,0.46))
	draw_rect(Rect2(0,610,width,6),Color("ddbd6d"))
	for p in platforms:
		draw_line(p.position+Vector2(4,2),p.position+Vector2(p.size.x-4,2),Color(0.94,0.78,0.44,0.70),3)

func platform_style() -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=Color("bc8b43")
	s.border_color=Color("e7c77f")
	s.set_border_width_all(2)
	s.set_corner_radius_all(7)
	return s

func room_for(x: float) -> int:
	return 0 if x < 1700 else 1 if x < 3700 else 2

func camera_target(x: float, feet_y: float = 610, rising: bool = false) -> Vector2:
	var bounds: Vector2 = Vector2(0,1550) if tutorial else ROOM_BOUNDS[room]
	var height=clampf(feet_y+100.0-(60.0 if rising else 0.0),60.0,360.0)
	return Vector2(clampf(x,bounds.x+640,bounds.y-640),height)

func enter_room(index: int) -> void:
	room = clampi(index,0,2)

func add_lights() -> void:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,0.85),Color(1,1,1,0)])
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	for pos in ([Vector2(550,250),Vector2(1200,250)] if tutorial else [Vector2(400,250),Vector2(1270,250),Vector2(2390,230),Vector2(3090,250),Vector2(4430,330),Vector2(5100,250)]):
		var lamp = PointLight2D.new()
		lamp.texture = texture
		lamp.position = pos
		lamp.texture_scale = 3.2
		lamp.color = Color("ffe4b4")
		lamp.energy = 0.18
		add_child(lamp)

func support_y(x: float, feet_y: float) -> float:
	var ground_y=610.0
	for platform in platforms:
		if x>=platform.position.x-6 and x<=platform.end.x+6 and platform.position.y>=feet_y-8:
			ground_y=minf(ground_y,platform.position.y)
	return ground_y


func land_on_ledge(at: Vector2, strength: float) -> void:
	for ledge in fun_ledges:
		if at.x>=ledge.position.x-14 and at.x<=ledge.position.x+ledge.width+14 and absf(at.y-ledge.position.y)<5:
			ledge.impact(strength)
