extends Node2D

var objects: Array[Dictionary] = []
var width: float = 5600
var tutorial: bool = false
var clock: float = 0
var reduced_motion: bool = false
var bark: Sprite2D
var platforms: Array[Rect2] = []
var markers: Array[Node2D] = []

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
	markers.clear()
	if tutorial:
		background("garden_hub",0,1550)
	else:
		background("school_hub",0,1700)
		background("garden_hub",1700,2000)
		background("school_hub",3700,1900)
		# Lightly darkened workshop section keeps foreground props readable.
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
		add_object("tutorial_notebook","collectibles_notebook",Vector2(680,610),"Your notebook",100)
		add_object("tutorial_leaf","collectibles_leaf_token",Vector2(840,545),"A bright leaf",65)
		add_object("tutorial_plane","collectibles_paper_plane",Vector2(1080,590),"Practice plane",110)
		add_object("tutorial_target","ui_parts_reward_check",Vector2(1370,480),"Practice target",115)
		bark = Art.character("bark_actions_idle")
		bark.position = Vector2(320,610)
		bark.scale = Vector2.ONE*0.26
		add_child(bark)
		world_label("THE QUIET GARDEN",Vector2(200,230),28)
	else:
		decorate("school_props_red_locker",Vector2(410,610),215)
		decorate("school_props_navy_locker",Vector2(565,610),215)
		decorate("school_props_bookcase",Vector2(1140,610),230)
		decorate("school_props_chair",Vector2(1310,610),155)
		add_object("invitation","school_props_noticeboard",Vector2(810,600),"Big Ideas Fair invitation",215)
		add_object("notebook","collectibles_notebook",Vector2(1910,600),"Mark's scattered design",110)
		add_object("plant_bed","school_props_stump",Vector2(2320,610),"Garden display · return the plant",180)
		add_object("plant","school_props_plant",Vector2(2840,610),"The wandering plant",145)
		for rect in [Rect2(1990,550,180,20),Rect2(2225,490,175,20),Rect2(2470,430,190,20),Rect2(2730,370,190,20),Rect2(2980,430,190,20),Rect2(3220,490,180,20)]:
			add_platform(rect,"school_props_log")
		add_object("books","collectibles_books",Vector2(3290,490),"Book base",95)
		add_object("pencil","collectibles_pencil",Vector2(3500,600),"Pencil guide",110)
		add_object("doodle_1","collectibles_notebook",Vector2(2550,430),"Notebook discovery",70)
		add_object("doodle_2","collectibles_notebook",Vector2(5200,600),"Notebook discovery",70)
		add_object("bark_token","collectibles_bark_token",Vector2(2820,350),"Bark's secret token",75)
		var leaf_positions = [Vector2(1480,540),Vector2(2090,525),Vector2(2390,600),Vector2(3100,405),Vector2(3850,540),Vector2(5330,540)]
		for i in range(6):
			add_object("leaf_"+str(i+1),"collectibles_leaf_token",leaf_positions[i],"Leaf discovery",55)
		add_object("shortcut","ui_parts_wood_button",Vector2(3630,610),"Garden shortcut to workshop",120)
		add_object("workshop","school_props_desk",Vector2(4430,610),"Mark & Bark's invention desk",310)
		add_object("fair_target","school_props_noticeboard",Vector2(5050,360),"The Big Ideas Fair target",205)
		add_object("volcano","school_props_science_volcano",Vector2(4020,610),"Bark's volcano inspection",185)
		decorate("school_props_chalkboard",Vector2(4620,320),240)
		decorate("school_props_lamp",Vector2(4310,460),100)
		world_label("THE SCHOOL HUB",Vector2(730,230),28)
		world_label("DISCOVERY GARDEN",Vector2(2100,230),28)
		world_label("THE BIG IDEAS WORKSHOP",Vector2(4400,210),26)
		bark = Art.character("bark_actions_idle")
		bark.scale = Vector2.ONE*0.26
		bark.position = Vector2(340,610)
		add_child(bark)
	refresh()
	queue_redraw()

func background(id: String, x: float, span: float) -> void:
	var s = Sprite2D.new()
	s.texture = Art.tex(id)
	s.centered = false
	s.position = Vector2(x,-305)
	s.scale = Vector2(span/s.texture.get_width(),915.0/s.texture.get_height())
	s.z_index = -5
	add_child(s)

func decorate(id: String, pos: Vector2, size: float) -> Sprite2D:
	var sprite = Art.prop(id,size)
	sprite.position = pos
	add_child(sprite)
	return sprite

func add_object(id: String, asset: String, pos: Vector2, title: String, size: float) -> void:
	var sprite = decorate(asset,pos,size)
	var label_node = world_label(title,pos+Vector2(-125,-size-34),16)
	label_node.modulate.a = 0.95
	objects.append({"id":id,"pos":pos,"sprite":sprite,"label":label_node,"title":title,"visible":true})

func world_label(text: String, pos: Vector2, size: int) -> Label:
	var l = Label.new()
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
		item.sprite.visible = show
		item.label.visible = show and not id.begins_with("leaf_")
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
		if d<best and absf(item.pos.y-pos.y)<145:
			found=item
			best=d
	return found

func _process(delta: float) -> void:
	clock+=delta
	for item in objects:
		if item.id.begins_with("leaf_") or item.id in ["tutorial_leaf","bark_token"]:
			item.sprite.position.y = item.pos.y if reduced_motion else item.pos.y+sin(clock*2+item.pos.x)*4

func _draw() -> void:
	var tile = Art.tex("garden_soil" if tutorial else "oak_floor")
	draw_texture_rect(tile,Rect2(0,610,width,110),true,Color(0.60,0.56,0.46))
	draw_rect(Rect2(0,610,width,6),Color("ddbd6d"))
	for p in platforms:
		draw_style_box(platform_style(),Rect2(p.position,p.size))

func platform_style() -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=Color("bc8b43")
	s.border_color=Color("e7c77f")
	s.set_border_width_all(2)
	s.set_corner_radius_all(7)
	return s
