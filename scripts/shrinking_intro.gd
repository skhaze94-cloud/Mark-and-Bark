extends Node2D

# A calm storybook ray reveal, with a static reduced-motion alternative.
var game
var running: bool = false
var age: float = 0.0
var root: Control
var title: Label
var caption: Label
var skip_button: Button
var done: Callable
var beam: float = 0.0
var ray_heard: bool = false
var staged: Array[Node] = []

func _ready() -> void:
	z_index=2
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	root.hide()
	game.hud.get_parent().add_child(root)
	for rect in [Rect2(0,0,1280,75),Rect2(0,600,1280,120)]:
		var bar=ColorRect.new()
		bar.position=rect.position
		bar.size=rect.size
		bar.color=Color("203849")
		root.add_child(bar)
	game.label_at(root,"THE FUNDATE · A SMALL ACCIDENT",Rect2(35,24,800,35),21,"e3c479")
	skip_button=game.button(root,"Skip intro  [E]",Rect2(1030,15,220,48),finish)
	title=game.label_at(root,"",Rect2(65,611,1150,36),25,"e3c479")
	caption=game.label_at(root,"",Rect2(65,654,1150,60),22,"fff2d5")
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func begin(callback: Callable) -> void:
	game.cancel_room_transition()
	game.close_modal()
	game.flight.clear()
	game.prediction.clear_points()
	game.mode="shrinking"
	game.busy=true
	game.hud.hide()
	game.player.enabled=false
	game.player.axis=0
	game.player.velocity=Vector2.ZERO
	game.player.right_bound=5600
	game.player.pose_lock=0
	game.player.visual_scale=0.42
	game.campus.build(false)
	game.campus.enter_room(2)
	game.player.position=Vector2(4680,610)
	game.campus.bark.position=Vector2(4850,610)
	game.campus.bark.scale=Vector2.ONE*0.35
	game.campus.bark.texture=Art.tex("bark_actions_point")
	game.camera.position=Vector2(4700,360)
	game.camera.zoom=Vector2.ONE
	game.ambient.color=Color("eee4d5")
	staged.append(game.campus.decorate("collectibles_books",Vector2(4210,610),200))
	staged.append(game.campus.decorate("collectibles_pencil",Vector2(4280,475),145))
	age=0
	ray_heard=false
	beam=0
	done=callback
	running=true
	skip_button.text="Skip intro" if game.input_touch or Progress.settings.touch else "Skip intro  [E]"
	root.show()
	update_story()

func _physics_process(delta: float) -> void:
	if not running:return
	age+=delta
	if age>=15:
		finish()
		return
	update_story()

func update_story() -> void:
	if age>=4 and not ray_heard:
		ray_heard=true
		game.play_sound("collect",1.35)
	var reduced=bool(Progress.settings.reduced_motion)
	var shrink=clampf((age-4.0)/2.8,0,1)
	if reduced:shrink=1.0 if age>=5.5 else 0.0
	var ease=shrink*shrink*(3-2*shrink)
	game.player.visual_scale=lerpf(0.42,0.24,ease)
	game.campus.bark.scale=Vector2.ONE*lerpf(0.35,0.20,ease)
	beam=0.24 if reduced and age>=4 and age<7 else sin(clampf((age-3.8)/3.6,0,1)*PI)*0.42 if not reduced and age>=3.8 and age<7.4 else 0.0
	if age<3.8:
		title.text="MARK: What if our big idea is too small?"
		caption.text="BARK: Easy! My new ray will make everything BIGGER. Probably."
	elif age<7.4:
		title.text="ONE DIAL. ONE VERY INTERESTING FIRST ATTEMPT."
		caption.text="MARK: Bark... that says SHRINK.   BARK: Ah. A tiny spelling mistake."
	elif age<11:
		title.text="SMALL FRIENDS. GIANT POSSIBILITIES."
		caption.text="MARK: The books are mountains!   BARK: And pencils are bridges. Excellent!"
	else:
		title.text="THE BIG IDEAS FAIR STILL NEEDS OUR INVITATION."
		caption.text="BARK: Jump once, then again! I'll give you a leafy lift. Let's practise outside."
	queue_redraw()

func _draw() -> void:
	if not running:return
	var ink=Color("203849")
	# The whimsical ray sits on a giant book: pencil barrel, oak body, gold lens.
	draw_style_box(machine_box(Color("63816d")),Rect2(4180,420,120,75))
	draw_rect(Rect2(4200,433,80,10),Color("e4c275"))
	draw_circle(Vector2(4250,464),14,ink)
	draw_line(Vector2(4250,464),Vector2(4259,455),Color("f5deb0"),3)
	draw_line(Vector2(4300,442),Vector2(4340,445),Color("be9650"),19)
	draw_circle(Vector2(4344,445),16,ink)
	draw_circle(Vector2(4344,445),11,Color("e5c875"))
	if beam>0:
		draw_colored_polygon(PackedVector2Array([Vector2(4344,445),Vector2(4980,340),Vector2(4980,610)]),Color(1.0,0.85,0.40,beam))
		draw_line(Vector2(4344,445),Vector2(4870,550),Color(1.0,0.92,0.63,beam*0.8),4)
	for pos in [Vector2(4175,575),Vector2(4315,573)]:
		draw_line(pos,pos+Vector2(0,-78),ink,8)

func machine_box(fill: Color) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=fill
	s.border_color=Color("203849")
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	return s

func finish() -> void:
	if not running:return
	running=false
	root.hide()
	beam=0
	queue_redraw()
	game.player.visual_scale=0.24
	game.player.pose_lock=0
	game.player.reset_jumps()
	game.busy=false
	for item in staged:
		if is_instance_valid(item):item.queue_free()
	staged.clear()
	Progress.data.shrunken=true
	Progress.save_game()
	var callback=done
	done=Callable()
	if callback.is_valid():callback.call()
