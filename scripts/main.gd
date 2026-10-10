extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const CampusScript = preload("res://scripts/campus.gd")
const GOALS = ["Read the Big Ideas Fair invitation in the school hallway.","Find Mark's scattered design notebook in the garden.","Find the wandering plant and return it to the stump display.","Collect the book base and pencil guide for your invention.","Bring your supplies to the classroom invention desk.","Assemble your paper-plane machine at the desk.","Test your invention and deliver the invitation to the fair board.","Big idea complete! Explore the campus and find its secrets."]
const TUTORIAL_GOALS = ["Walk right to meet Bark.","Jump over the low log. You can try as often as you like.","Walk to your notebook and interact with it.","Collect the bright leaf just ahead.","Ask Bark for a hint.","Interact with the practice plane for a gentle launch.","Watch your paper plane reach the target!"]
var campus: Node2D
var player: CharacterBody2D
var camera: Camera2D
var hud: Control
var overlay: Control
var modal: Panel
var objective: Label
var counter: Label
var prompt: Label
var prompt_panel: Panel
var zone_label: Label
var toast_label: Label
var mode: String = "title"
var busy: bool = false
var tutorial_step: int = 0
var tutorial_jumped: bool = false
var tutorial_seen_jump: bool = false
var touches: Dictionary = {"left":false,"right":false}
var touch_fingers: Dictionary = {}
var touch_root: Control
var input_touch: bool = false
var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_done: Callable
var dialogue_text: Label
var dialogue_speaker: Label
var dialogue_portrait: TextureRect
var toast_time: float = 0
var idle_time: float = 0
var last_zone: String = ""
var angle_choice: int = 1
var power_choice: int = 0
var show_prediction: bool = false
var flight: Dictionary = {}
var plane: Sprite2D
var prediction: Line2D
var clock: float = 0
var checkpoint: float = 220
var sound_player: AudioStreamPlayer
var sounds: Dictionary = {}
var checkpoint_save_timer: float = 0
var pending_end: bool = false
var transition_panel: ColorRect
var transition_title: Label
var room_transition: Dictionary = {}
var transitions_completed: int = 0
var ambient: CanvasModulate
var cinema
var finish_material: ShaderMaterial
var bark_pose_until: float = 0.0

func sync_room() -> void:
	campus.enter_room(campus.room_for(player.position.x))
	last_zone = campus.ROOM_NAMES[campus.room]
	camera.position = campus.camera_target(player.position.x)
	campus.bark.position = Vector2(player.position.x-90*player.facing,610)
	ambient.color = Color("eef1e4") if campus.room==1 else Color("e4e5e8") if campus.room==0 else Color("eee4d5")

func check_room_exit() -> void:
	var x: float = player.position.x
	match campus.room:
		0:
			if x>1688:begin_room_transition(1,1745,"Out into the discovery garden")
		1:
			if x<1712:begin_room_transition(0,1655,"Back inside the school")
			elif x>3688:begin_room_transition(2,3745,"Into the invention workshop")
		2:
			if x<3712:begin_room_transition(1,3655,"Back out to the garden")

func begin_room_transition(to_room: int, arrival_x: float, title: String) -> void:
	if not room_transition.is_empty():return
	room_transition = {"room":to_room,"arrival":arrival_x,"age":0.0,"arrived":false}
	player.enabled=false
	player.axis=0
	player.velocity=Vector2.ZERO
	touches.left=false
	touches.right=false
	touch_fingers.clear()
	transition_title.text=title
	transition_panel.modulate.a=0
	transition_panel.show()
	prompt.text=""

func update_room_transition(delta: float) -> void:
	room_transition.age += delta
	var duration: float = 0.24 if Progress.settings.reduced_motion else 0.85
	var progress: float = room_transition.age/duration
	transition_panel.modulate.a=clampf(progress*2 if progress<0.5 else (1-progress)*2,0,1)
	if progress>=0.5 and not room_transition.arrived:
		room_transition.arrived=true
		player.position=Vector2(room_transition.arrival,605)
		player.velocity=Vector2.ZERO
		sync_room()
		checkpoint=player.position.x
		Progress.set_checkpoint(checkpoint)
		update_hud()
	if progress>=1:
		transitions_completed+=1
		cancel_room_transition()
		player.enabled=not busy
		toast("Welcome to "+last_zone.to_lower()+". Your discoveries came with you.")

func cancel_room_transition() -> void:
	room_transition.clear()
	if is_instance_valid(transition_panel):transition_panel.hide()

func _ready() -> void:
	configure_input()
	campus = CampusScript.new()
	add_child(campus)
	campus.build(true)
	player = PlayerScript.new()
	add_child(player)
	player.position=Vector2(960,610)
	player.enabled=false
	camera=Camera2D.new()
	camera.position=Vector2(640,360)
	add_child(camera)
	camera.make_current()
	prediction=Line2D.new()
	prediction.width=4
	prediction.default_color=Color(1,0.9,0.5,0.8)
	prediction.z_index=8
	add_child(prediction)
	sound_player=AudioStreamPlayer.new()
	add_child(sound_player)
	for key in ["collect","jump","success","miss"]:
		var path="res://assets/"+key+".wav"
		if ResourceLoader.exists(path):
			sounds[key]=load(path)
	ambient = CanvasModulate.new()
	ambient.color = Color("edece1")
	add_child(ambient)
	build_world_finish()
	build_ui()
	cinema=load("res://scripts/campus_film.gd").new()
	cinema.game=self
	add_child(cinema)
	apply_settings()
	show_title()

func configure_input() -> void:
	var mapping={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E,KEY_ENTER],"hint":[KEY_H],"pause":[KEY_ESCAPE]}
	for action in mapping:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in mapping[action]:
			var event=InputEventKey.new()
			event.physical_keycode=code
			InputMap.action_add_event(action,event)

func panel_style(color: String = "f4ecd8") -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=Color(color)
	s.border_color=Color("d3ac53")
	s.set_border_width_all(3)
	s.set_corner_radius_all(18)
	s.shadow_color=Color(0,0,0,0.24)
	s.shadow_size=12
	return s

func label_at(parent: Node, text: String, rect: Rect2, size: int = 22, color: String = "203849") -> Label:
	var l=Label.new()
	l.text=text
	l.position=rect.position
	l.size=rect.size
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font",Art.font)
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color(color))
	parent.add_child(l)
	return l

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var b=Button.new()
	b.text=text
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_override("font",Art.font)
	b.add_theme_font_size_override("font_size",20)
	b.add_theme_color_override("font_color",Color("fff3d5") if primary else Color("203849"))
	b.add_theme_stylebox_override("normal",panel_style("203849" if primary else "fff5dc"))
	b.add_theme_stylebox_override("hover",panel_style("365c6d" if primary else "e7d198"))
	b.add_theme_stylebox_override("pressed",panel_style("1a313f" if primary else "d8bb73"))
	b.add_theme_stylebox_override("focus",panel_style("365c6d" if primary else "e7d198"))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func build_ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=20
	add_child(layer)
	hud=Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	var top=Panel.new()
	top.position=Vector2(22,18)
	top.size=Vector2(1236,115)
	top.add_theme_stylebox_override("panel",panel_style("203849"))
	hud.add_child(top)
	zone_label=label_at(top,"THE BIG IDEA",Rect2(20,10,780,28),18,"e3c479")
	objective=label_at(top,"",Rect2(20,43,780,60),22,"fff5dd")
	counter=label_at(top,"",Rect2(850,15,180,86),17,"fff5dd")
	button(top,"Pause",Rect2(1070,28,145,55),show_pause)
	prompt_panel=Panel.new()
	prompt_panel.position=Vector2(255,638)
	prompt_panel.size=Vector2(720,54)
	prompt_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var prompt_style=panel_style("203849")
	prompt_style.bg_color.a=0.92
	prompt_style.set_border_width_all(1)
	prompt_style.shadow_size=3
	prompt_panel.add_theme_stylebox_override("panel",prompt_style)
	hud.add_child(prompt_panel)
	prompt=label_at(prompt_panel,"",Rect2(12,8,696,38),20,"fff5dd")
	prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",Color("172e3c"))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	toast_label=label_at(hud,"",Rect2(270,155,740,70),22,"fff2bd")
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color",Color("172e3c"))
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	button(hud,"Bark's hint  [H]",Rect2(985,624,265,68),request_hint)
	button(hud,"Notebook",Rect2(1018,545,232,60),show_notebook)
	button(hud,"Skip tutorial",Rect2(24,155,180,50),finish_tutorial).name="SkipTutorial"
	touch_root=Control.new()
	touch_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(touch_root)
	for spec in [["left","◀",Rect2(25,609,90,88)],["right","▶",Rect2(130,609,90,88)]]:
		var b=button(touch_root,spec[1],spec[2],func():pass,true)
		b.button_down.connect(func():touches[spec[0]]=true)
		b.button_up.connect(func():touches[spec[0]]=false)
	button(touch_root,"Jump",Rect2(255,609,140,88),jump_pressed,true)
	button(touch_root,"Use",Rect2(420,609,140,88),interact_pressed,true)
	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	transition_panel = ColorRect.new()
	transition_panel.color = Color("172f39")
	transition_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_panel.visible = false
	layer.add_child(transition_panel)
	transition_title = label_at(transition_panel,"",Rect2(160,295,960,80),36,"f8e9be")
	transition_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle = label_at(transition_panel,"A new place. The same big idea.",Rect2(260,391,760,48),20,"c6d7c1")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func close_modal() -> void:
	if is_instance_valid(modal):
		overlay.remove_child(modal)
		modal.queue_free()
	modal=null
	busy=false
	touches.left=false
	touches.right=false
	touch_fingers.clear()
	player.enabled=mode in ["tutorial","campus"] and flight.is_empty() and room_transition.is_empty()

func open_modal(rect: Rect2) -> Panel:
	close_modal()
	busy=true
	player.enabled=false
	modal=Panel.new()
	modal.position=rect.position
	modal.size=rect.size
	modal.add_theme_stylebox_override("panel",panel_style())
	modal.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.add_child(modal)
	return modal

func show_title() -> void:
	mode="title"
	flight.clear()
	hud.visible=false
	var p=open_modal(Rect2(65,50,580,625))
	label_at(p,"MARK & BARK",Rect2(34,25,520,64),42)
	label_at(p,"THE BIG IDEA",Rect2(36,92,500,45),28,"977134")
	label_at(p,"One curious kid. One very lively tree.\nOne invention waiting to happen.",Rect2(36,150,505,83),22)
	button(p,"Continue adventure" if Progress.tutorial_done else "Start adventure",Rect2(36,253,506,64),start_continue,true)
	button(p,"New adventure",Rect2(36,332,244,57),confirm_new)
	button(p,"Replay tutorial",Rect2(296,332,246,57),start_tutorial)
	button(p,"Settings & controls",Rect2(36,407,506,57),func():show_settings(show_title))
	button(p,"Watch the campus film",Rect2(36,480,506,53),func():cinema.begin(return_from_film))
	label_at(p,"Move: A/D or arrows · Jump: Space\nInteract: E · Hint: H · Pause: Esc",Rect2(36,546,510,52),16)
	camera.position=Vector2(640,360)
	player.enabled=false

func confirm_new() -> void:
	var p=open_modal(Rect2(330,190,620,330))
	label_at(p,"Start a new adventure?",Rect2(30,26,560,50),30)
	label_at(p,"This resets your current quest and discoveries. Your accessibility settings stay the same.",Rect2(30,95,560,95),22)
	button(p,"Keep my adventure",Rect2(30,220,260,65),show_title)
	button(p,"Start fresh",Rect2(320,220,270,65),func():Progress.reset_game();cinema.begin(start_tutorial),true)

func start_continue() -> void:
	if Progress.tutorial_done:
		start_campus()
	else:
		cinema.begin(start_tutorial)

func start_tutorial() -> void:
	cancel_room_transition()
	close_modal()
	mode="tutorial"
	tutorial_step=0
	tutorial_jumped=false
	tutorial_seen_jump=false
	campus.build(true)
	player.position=Vector2(120,605)
	player.velocity=Vector2.ZERO
	player.right_bound=1550
	hud.visible=true
	player.enabled=true
	idle_time=0
	camera.position=Vector2(640,360)
	say(["Mark|What if my invention doesn't work?","Bark|Then we've invented a very interesting first attempt.","Mark|You've already tried it, haven't you?","Bark|Define 'tried.' And possibly 'where the supplies went.'\nLet's practise in the quiet garden first!"])
	update_hud()

func finish_tutorial() -> void:
	Progress.tutorial_done=true
	Progress.save_game()
	start_campus()

func start_campus() -> void:
	cancel_room_transition()
	close_modal()
	mode="campus"
	flight.clear()
	prediction.clear_points()
	if is_instance_valid(plane):
		plane.queue_free()
	campus.build(false)
	player.position=Vector2(float(Progress.data.checkpoint),605)
	player.velocity=Vector2.ZERO
	player.right_bound=5600
	checkpoint=player.position.x
	hud.visible=true
	player.enabled=true
	idle_time=0
	sync_room()
	if int(Progress.data.stage)==0:
		say(["Bark|Tiny update: the supplies are now enjoying a tour of the garden.","Mark|We'll find them. And build something worth showing.","Bark|That's the spirit! Start with the fair invitation on the hallway board."])
	update_hud()

func say(lines: Array, done: Callable = Callable()) -> void:
	dialogue_lines=lines
	dialogue_index=0
	dialogue_done=done
	var p=open_modal(Rect2(60,430,1160,250))
	dialogue_portrait=TextureRect.new()
	dialogue_portrait.position=Vector2(20,15)
	dialogue_portrait.size=Vector2(155,190)
	dialogue_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(dialogue_portrait)
	dialogue_speaker=label_at(p,"",Rect2(192,18,780,36),23,"977134")
	dialogue_text=label_at(p,"",Rect2(192,62,922,120),22)
	button(p,"Skip story",Rect2(195,183,190,50),dismiss_dialogue)
	button(p,"Next  [E]",Rect2(912,183,210,50),next_dialogue,true)
	refresh_dialogue()

func refresh_dialogue() -> void:
	var parts=String(dialogue_lines[dialogue_index]).split("|",true,1)
	dialogue_speaker.text=parts[0]
	dialogue_text.text=parts[1] if parts.size()>1 else parts[0]
	dialogue_portrait.texture=Art.tex("young_front" if parts[0]=="Mark" else "bark_actions_hint")

func next_dialogue() -> void:
	if not is_instance_valid(dialogue_text) or not is_instance_valid(modal):
		return
	dialogue_index+=1
	if dialogue_index>=dialogue_lines.size():
		dismiss_dialogue()
	else:
		refresh_dialogue()

func dismiss_dialogue() -> void:
	var callback=dialogue_done
	dialogue_done=Callable()
	dialogue_text=null
	close_modal()
	if callback.is_valid():
		callback.call()

func _input(event: InputEvent) -> void:
	if mode=="cinematic" and event is InputEventScreenTouch:
		input_touch=true
		cinema.skip_button.text="Skip film"
		if event.pressed and Rect2(1040,9,214,46).has_point(event.position):
			cinema.finish()
			get_viewport().set_input_as_handled()
		return
	if not room_transition.is_empty():
		if event is InputEventScreenTouch:get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		input_touch=true
		apply_settings()
		# Explicit multitouch avoids relying on first-finger mouse emulation.
		if event.pressed and not busy and mode in ["tutorial","campus"]:
			if Rect2(25,609,90,88).has_point(event.position):
				touch_fingers[event.index]="left"
			elif Rect2(130,609,90,88).has_point(event.position):
				touch_fingers[event.index]="right"
			elif Rect2(255,609,140,88).has_point(event.position):
				jump_pressed()
				get_viewport().set_input_as_handled()
			elif Rect2(420,609,140,88).has_point(event.position):
				interact_pressed()
				get_viewport().set_input_as_handled()
		elif not event.pressed:
			touch_fingers.erase(event.index)
		touches.left="left" in touch_fingers.values()
		touches.right="right" in touch_fingers.values()
		if touch_fingers.has(event.index):get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touch_fingers.has(event.index):
		var direction=touch_fingers[event.index]
		var region=Rect2(25,609,90,88) if direction=="left" else Rect2(130,609,90,88)
		if not region.grow(20).has_point(event.position):touch_fingers.erase(event.index)
		touches.left="left" in touch_fingers.values()
		touches.right="right" in touch_fingers.values()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		input_touch=false
		apply_settings()

func _unhandled_input(event: InputEvent) -> void:
	if mode=="cinematic":
		if event.is_action_pressed("interact") or event.is_action_pressed("pause"):cinema.finish()
		get_viewport().set_input_as_handled()
		return
	if not room_transition.is_empty():
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if busy and mode!="title":
			if is_instance_valid(dialogue_text):dismiss_dialogue()
			else:close_modal()
		elif mode!="title":show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if busy:
			if is_instance_valid(dialogue_text):next_dialogue()
		else:interact_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		jump_pressed()
	elif event.is_action_pressed("hint"):
		request_hint()

func jump_pressed() -> void:
	if not busy and mode in ["tutorial","campus"] and flight.is_empty():
		player.request_jump()
		play_sound("jump")

func _physics_process(delta: float) -> void:
	clock+=delta
	if mode in ["title","cinematic"]:
		return
	if not room_transition.is_empty():
		update_room_transition(delta)
		return
	if mode=="campus" and not busy and flight.is_empty():
		check_room_exit()
		if not room_transition.is_empty(): return
	player.reduced_motion=bool(Progress.settings.reduced_motion)
	campus.reduced_motion=player.reduced_motion
	if not busy and flight.is_empty():
		player.axis=clampf(Input.get_axis("left","right")+float(touches.right)-float(touches.left),-1,1)
	else:
		player.axis=0
	var framing_x: float = player.position.x
	if not flight.is_empty() and flight.kind=="workshop" and not Progress.settings.reduced_motion:
		framing_x += minf(float(flight.t)*100.0,380.0)
	var target=campus.camera_target(framing_x)
	camera.position=target if Progress.settings.reduced_motion else camera.position.lerp(target,1-exp(-delta*5))
	var bounds: Vector2 = Vector2(0,1550) if mode=="tutorial" else campus.ROOM_BOUNDS[campus.room]
	camera.position.x = clampf(camera.position.x,bounds.x+640,bounds.y-640)
	campus.depth.camera_x = camera.position.x
	campus.foreground.camera_x = camera.position.x
	campus.scenery.camera_x = camera.position.x
	if not busy and flight.is_empty():
		idle_time+=delta
		if absf(player.velocity.x)>20:idle_time=0
		if idle_time>22:
			toast("Bark: Need a clue? Use the hint button. There's always another try.")
			idle_time=0
		if mode=="tutorial":
			update_tutorial()
		else:
			collect_nearby()
			update_checkpoint(delta)
	if player.position.y>900:
		restart_checkpoint()
	if is_instance_valid(campus.bark):
		var follow_x=player.position.x-90*player.facing
		if not (mode=="tutorial" and tutorial_step==0):
			campus.bark.position.x=lerpf(campus.bark.position.x,follow_x,1-exp(-delta*3))
			campus.bark.position.y=610
		campus.bark.scale.x=0.26*player.facing
		if not busy and clock>bark_pose_until:
			var frames = ["bark_actions_walk_stride_a","bark_actions_walk_passing","bark_actions_walk_stride_b","bark_actions_walk_passing"]
			var walking = absf(campus.bark.position.x-follow_x)>15
			campus.bark.texture=Art.tex(frames[int(clock*6)%4] if walking else "bark_actions_idle")
			campus.bark.scale.y=0.26 if Progress.settings.reduced_motion or walking else 0.26*(1+sin(clock*1.8)*0.009)
	update_flight(delta)
	toast_time-=delta
	toast_label.visible=toast_time>0
	update_hud()

func update_tutorial() -> void:
	if player.position.x>390 and player.position.x<610 and player.position.y<575:
		tutorial_seen_jump=true
	if tutorial_step==0 and player.position.x>=265:
		tutorial_step=1
		say(["Bark|Hello, inventor! Next, jump over that little log.\nSpace or the Jump button will do it."])
	elif tutorial_step==1 and player.position.x>550 and tutorial_seen_jump:
		tutorial_step=2
		toast("Great jump! Now open your notebook.")
	elif tutorial_step==3 and player.position.distance_to(Vector2(840,545))<95:
		tutorial_step=4
		var leaf=campus.object("tutorial_leaf")
		leaf.visible=false
		leaf.sprite.hide()
		leaf.label.hide()
		play_sound("collect")
		toast("A leaf discovery! Now ask Bark for a hint.")

func collect_nearby() -> void:
	for item in campus.objects:
		if item.id.begins_with("leaf_") and item.visible and player.position.distance_to(item.pos)<95:
			campus.depth.burst(item.pos+Vector2(0,-35))
			Progress.collect_leaf(item.id)
			campus.refresh()
			play_sound("collect")
			toast("Leaf found! "+str(Progress.data.leaves.size())+" / 6 discoveries")

func update_checkpoint(delta: float) -> void:
	checkpoint_save_timer+=delta
	var zone="SCHOOL HALLWAY" if player.position.x<1700 else "DISCOVERY GARDEN" if player.position.x<3700 else "CLASSROOM WORKSHOP"
	if zone!=last_zone:
		last_zone=zone
		if player.is_on_floor() and player.position.y>580:
			checkpoint=player.position.x
			Progress.set_checkpoint(checkpoint)
	if checkpoint_save_timer>8 and player.is_on_floor() and player.position.y>580:
		checkpoint=player.position.x
		Progress.set_checkpoint(checkpoint)
		checkpoint_save_timer=0

func update_hud() -> void:
	if mode=="title":return
	objective.text=TUTORIAL_GOALS[mini(tutorial_step,6)] if mode=="tutorial" else GOALS[clampi(int(Progress.data.stage),0,7)]
	zone_label.text="GARDEN TUTORIAL" if mode=="tutorial" else last_zone
	counter.text="Learn at your pace\nNo lost discoveries" if mode=="tutorial" else "Leaves  "+str(Progress.data.leaves.size())+" / 6\nNotes   "+str(Progress.data.discoveries.size())+" / 2\nBark token  "+("Found!" if Progress.data.bark_token else "Hidden")
	hud.get_node("SkipTutorial").visible=mode=="tutorial"
	touch_root.visible=bool(Progress.settings.touch) or input_touch or OS.has_feature("mobile")
	if busy or not flight.is_empty():
		prompt.text=""
	else:
		var item=campus.nearest(player.position)
		prompt.text=("Use: " if touch_root.visible else "[E] ")+String(item.title) if not item.is_empty() else ""

	prompt_panel.visible=not prompt.text.is_empty()
	prompt_panel.position=Vector2(255,547 if touch_root.visible else 638)

func interact_pressed() -> void:
	if busy or not flight.is_empty() or not mode in ["tutorial","campus"]:
		return
	var item=campus.nearest(player.position)
	if item.is_empty():
		toast("Walk a little closer to a notebook, sign or invention.")
		return
	interact_object(item.id)

func interact_object(id: String) -> void:
	idle_time=0
	if mode=="tutorial":
		if id=="tutorial_notebook" and tutorial_step==2:
			tutorial_step=3
			player.show_pose("young_actions_notebook",1)
			say(["Mark|My notebook! Every invention starts with a question.","Bark|Mine starts with 'what happens if I poke this?'\nNow collect that lovely leaf."])
		elif id=="tutorial_plane" and tutorial_step==5:
			tutorial_step=6
			launch_tutorial()
		else:
			toast("Let's finish the current garden lesson first.")
		return
	var stage=int(Progress.data.stage)
	match id:
		"invitation":
			if stage==0:
				Progress.advance(1)
				say(["Mark|Big Ideas Fair: bring an invention, a question, and a friend.","Bark|Three things! I've brought seventeen questions.\nLet's recover your design from the garden."])
			else:say(["Bark|The fair welcomes first attempts, second attempts, and friends. Especially tree friends."])
		"notebook":
			if stage<1:
				toast("Read the fair invitation first. It's on the school noticeboard.")
			else:
				Progress.data.notebook=true
				Progress.advance(2)
				player.show_pose("young_actions_notebook",1)
				campus.refresh()
				say(["Mark|A book base, a pencil guide, and a puff of wind. A paper-plane delivery machine!","Bark|A very scientific puff.\nAlso, I may have borrowed the garden's plant. Let's put it back."])
		"plant":
			if stage<2:toast("Let's recover the design notebook first.")
			else:
				Progress.data.plant=true
				Progress.save_game()
				campus.refresh()
				toast("Plant picked up. Return it to the stump display to the left.")
		"plant_bed":
			if Progress.data.plant and not Progress.data.plant_restored:
				Progress.data.plant_restored=true
				Progress.advance(3)
				campus.refresh()
				play_sound("success")
				say(["Mark|There. Back where it belongs.","Bark|A little helping makes a big difference!\nThe garden shortcut is open. Find the books on the low branch route and the pencil near the workshop."])
			else:toast("This display is waiting for its potted plant. Find it farther right in the garden.")
		"books","pencil":
			if stage<3:toast("Help restore the garden display first.")
			else:
				Progress.data[id]=true
				play_sound("collect")
				if Progress.data.books and Progress.data.pencil:Progress.advance(4)
				Progress.save_game()
				campus.refresh()
				toast("Book base collected!" if id=="books" else "Pencil guide collected!")
		"workshop":
			if stage<4:
				say(["Bark|Our workshop is ready when you are.\nRecover the notebook, return the plant, and collect the books and pencil."])
			else:
				if stage==4:Progress.advance(5)
				show_workshop()
		"shortcut":
			if Progress.data.plant_restored:
				begin_room_transition(2,4240,"Bark's garden shortcut")
		"bark_token":
			Progress.data.bark_token=true
			Progress.save_game()
			campus.refresh()
			play_sound("collect")
			say(["Bark|You found my secret token! It's an extremely accurate portrait.","Mark|It has your grin.","Bark|And excellent bark-to-face proportions."])
		"doodle_1","doodle_2":
			if not id in Progress.data.discoveries:Progress.data.discoveries.append(id)
			Progress.save_game()
			campus.refresh()
			var note="Invention #4: a backpack that does your homework.\nProblem: it only writes 'snacks'." if id=="doodle_1" else "Invention #9: an umbrella for trees.\nBark's review: 'Finally, someone understands my hair.'"
			say(["Mark|"+note,"Bark|An excellent idea. Needs more leaves."])
		"volcano":
			say(["Bark|I inspected the volcano. Very bubbly. Slightly rude to my toes.","Mark|It's a classroom experiment, Bark.","Bark|Then my toes have learned something."])
	update_hud()

func request_hint() -> void:
	if busy or mode=="title" or not flight.is_empty():return
	campus.bark.texture=Art.tex("bark_actions_hint")
	bark_pose_until=clock+3
	if mode=="tutorial":
		if tutorial_step==4:
			tutorial_step=5
			say(["Bark|Good inventors ask questions!\nWalk to the paper plane on the right and interact to launch it."])
		else:say(["Bark|"+TUTORIAL_GOALS[mini(tutorial_step,6)]+"\nThere is no hurry. We can try again."])
	else:
		var clues=["The hallway noticeboard is between the lockers and the reading nook.","The notebook is at the garden entrance, just right of the school.","Pick up the plant farther right in the garden, then return it to the stump display on the left.","Books are on the lowest right-hand garden branch. Jump up from below! The pencil is just beyond it.","The invention desk is in the classroom on the far right. The garden shortcut can help.","At the desk, add the books, then the pencil, then load your plane.","Try the middle angle and medium power. I'll show you the flight path at the workshop.","Six leaves, two funny notebook pages, and one secret Bark token are waiting to be found!"]
		show_prediction=true
		say(["Bark|"+clues[clampi(int(Progress.data.stage),0,7)]])

func show_notebook() -> void:
	if busy or mode=="title":return
	var p=open_modal(Rect2(255,160,770,410))
	label_at(p,"MARK'S NOTEBOOK",Rect2(30,25,710,42),30)
	var items="Design notebook: "+("Recovered" if Progress.data.notebook else "In the garden")+"\nGarden display: "+("Restored" if Progress.data.plant_restored else "Needs its plant")+"\nBook base: "+("Collected" if Progress.data.books else "Not yet")+"\nPencil guide: "+("Collected" if Progress.data.pencil else "Not yet")
	label_at(p,items,Rect2(32,90,710,175),23)
	label_at(p,"Big ideas grow through little improvements.\nOptional discoveries never block the adventure.",Rect2(32,270,700,66),18)
	button(p,"Back to exploring",Rect2(240,335,300,55),close_modal,true)

func show_workshop() -> void:
	var p=open_modal(Rect2(135,140,1010,520))
	label_at(p,"THE BIG IDEA WORKSHOP",Rect2(28,20,920,45),30)
	var built=int(Progress.data.assembled)
	if built<3:
		var desc=["Place the book base. A sturdy idea needs a sturdy beginning.","Add the pencil guide. Give your plane a direction.","Load the paper plane. Bark will provide one very scientific puff."]
		label_at(p,desc[built],Rect2(34,89,590,110),24)
		var image=TextureRect.new()
		image.texture=Art.tex(["collectibles_books","collectibles_pencil","collectibles_paper_plane"][built])
		image.position=Vector2(666,80)
		image.size=Vector2(285,280)
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.add_child(image)
		button(p,["Place books","Add pencil","Load plane"][built],Rect2(34,230,535,80),assemble_next,true)
		label_at(p,"Assembly "+str(built)+" / 3\nYour components appear on the desk as you build.",Rect2(34,335,600,90),21)
	else:
		label_at(p,"Choose your angle",Rect2(32,85,450,36),22)
		for i in range(3):
			var b=button(p,["Low 25°","Middle 40°","High 55°"][i],Rect2(32+i*315,128,295,66),func():angle_choice=i;show_workshop(),i==angle_choice)
			b.tooltip_text="Launch angle preset"
		label_at(p,"Choose the strength of Bark's puff",Rect2(32,215,920,40),22)
		for i in range(3):
			button(p,["Gentle","Medium","Strong"][i],Rect2(32+i*315,265,295,66),func():power_choice=i;show_workshop(),i==power_choice)
		label_at(p,"Every attempt is progress. Your plane always returns.",Rect2(32,354,915,40),20)
		button(p,"Show flight hint",Rect2(32,407,280,66),func():show_prediction=true;angle_choice=1;power_choice=1;close_modal();draw_prediction();toast("Bark: Middle angle + medium puff. Follow the golden arc."))
		button(p,"Test invention!",Rect2(646,407,310,66),launch_workshop,true)
	button(p,"Explore",Rect2(720,22,235,48),close_modal)

func assemble_next() -> void:
	Progress.data.assembled=mini(3,int(Progress.data.assembled)+1)
	if int(Progress.data.assembled)==3:Progress.advance(6)
	Progress.save_game()
	campus.refresh()
	play_sound("collect")
	show_workshop()

func trajectory(t: float, angle: int = angle_choice, power: int = power_choice) -> Vector2:
	var radians=deg_to_rad([25.0,40.0,55.0][angle])
	var speed=[350.0,470.0,600.0][power]
	return Vector2(4430,425)+Vector2(cos(radians)*speed*t,-sin(radians)*speed*t+125*t*t)

func draw_prediction() -> void:
	prediction.clear_points()
	if not show_prediction:return
	for i in range(53):
		var pos=trajectory(i*0.045)
		if pos.y>610:break
		prediction.add_point(pos)

func launch_tutorial() -> void:
	close_modal()
	spawn_plane(Vector2(1080,510))
	flight={"kind":"tutorial","t":0.0}
	player.enabled=false
	player.show_pose("young_actions_paper_plane",1.3)
	toast("Bark: A gentle puff. Off it goes!")

func spawn_plane(pos: Vector2) -> void:
	if is_instance_valid(plane):plane.queue_free()
	plane=Art.prop("collectibles_paper_plane",95)
	plane.position=pos
	plane.z_index=10
	add_child(plane)

func launch_workshop() -> void:
	if int(Progress.data.assembled)<3:return
	close_modal()
	Progress.data.attempts=int(Progress.data.attempts)+1
	Progress.save_game()
	spawn_plane(trajectory(0))
	flight={"kind":"workshop","t":0.0,"angle":angle_choice,"power":power_choice,"previous":trajectory(0)}
	player.position=Vector2(4520,605)
	player.enabled=false
	player.show_pose("young_actions_paper_plane",1.5)
	if int(Progress.data.attempts)>=3:show_prediction=true
	draw_prediction()
	toast("Bark: Scientific puff incoming!")

func update_flight(delta: float) -> void:
	if flight.is_empty():return
	flight.t=float(flight.t)+delta
	if flight.kind=="tutorial":
		var t=clampf(float(flight.t)/1.5,0,1)
		plane.position=Vector2(1080,510).lerp(Vector2(1370,425),t)+Vector2(0,-sin(t*PI)*50)
		if t>=1:
			flight.clear()
			plane.queue_free()
			play_sound("success")
			say(["Mark|It worked!","Bark|Of course! Now for my BIG demonstration—","Bark|...Ah. The supplies have gone on an adventure. Let's follow them."],finish_tutorial)
		return
	var pos=trajectory(float(flight.t),int(flight.angle),int(flight.power))
	var previous: Vector2=flight.previous
	plane.position=pos
	plane.rotation=(pos-previous).angle()
	flight.previous=pos
	# Swept target crossing is frame-rate independent and tolerant.
	if previous.x<=5050 and pos.x>=5050:
		var crossed=previous.lerp(pos,(5050-previous.x)/maxf(0.001,pos.x-previous.x))
		if absf(crossed.y-290)<90:
			complete_invention()
			return
	if pos.y>640 or pos.x>5300 or float(flight.t)>5:
		flight.clear()
		plane.queue_free()
		player.enabled=true
		play_sound("miss")
		say(["Bark|Excellent! We now know where the target isn't.","Mark|Let's adjust our angle or power. The plane is ready to try again."],show_workshop)

func complete_invention() -> void:
	flight.clear()
	if is_instance_valid(plane):plane.queue_free()
	prediction.clear_points()
	Progress.data.completed=true
	Progress.advance(7)
	Progress.set_checkpoint(4520)
	campus.bark.texture=Art.tex("bark_actions_cheer")
	bark_pose_until=clock+8
	campus.depth.burst(Vector2(5050,290))
	play_sound("success")
	say(["Mark|It worked!","Bark|Of course. We only had to discover twelve ways it didn't.","Mark|Three.","Bark|I was counting the ones before you arrived.","Mark|A first attempt, a better idea, and a friend. That's what we'll bring to the fair."],show_ending)

func show_ending() -> void:
	var p=open_modal(Rect2(235,130,810,490))
	label_at(p,"BIG IDEA COMPLETE",Rect2(35,25,735,58),37)
	label_at(p,"Your invitation has reached the fair!\nYou built, experimented, helped, and tried again.",Rect2(35,100,730,86),23)
	var image=TextureRect.new()
	image.texture=Art.tex("collectibles_science_rosette")
	image.position=Vector2(560,205)
	image.size=Vector2(175,175)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(image)
	label_at(p,"Leaf discoveries: "+str(Progress.data.leaves.size())+" / 6\nFunny notebook pages: "+str(Progress.data.discoveries.size())+" / 2\nBark's secret token: "+("Found!" if Progress.data.bark_token else "Still waiting")+"\nInvention tests: "+str(Progress.data.attempts),Rect2(35,215,530,158),23)
	button(p,"Explore the campus",Rect2(35,400,355,62),close_modal,true)
	button(p,"Play again",Rect2(420,400,350,62),func():Progress.reset_game();cinema.begin(start_tutorial))
	toast("A science rosette for curiosity, friendship, and your big idea!")

func show_pause() -> void:
	if mode=="title" or not flight.is_empty() or (busy and is_instance_valid(dialogue_text)):return
	var p=open_modal(Rect2(390,150,500,455))
	label_at(p,"A LITTLE BREATHER",Rect2(25,22,450,50),29)
	button(p,"Continue",Rect2(30,95,440,60),close_modal,true)
	button(p,"Restart checkpoint",Rect2(30,173,440,60),restart_checkpoint)
	button(p,"Settings & controls",Rect2(30,250,440,60),func():show_settings(show_pause))
	button(p,"Save & title screen",Rect2(30,329,440,60),func():Progress.save_game();show_title())

func restart_checkpoint() -> void:
	cancel_room_transition()
	close_modal()
	flight.clear()
	prediction.clear_points()
	if is_instance_valid(plane):plane.queue_free()
	player.velocity=Vector2.ZERO
	player.position=Vector2(120 if mode=="tutorial" else checkpoint,605)
	player.enabled=true
	if mode=="campus":sync_room()
	toast("A fresh start nearby. Your discoveries are safe.")

func show_settings(back: Callable) -> void:
	var p=open_modal(Rect2(250,125,780,505))
	label_at(p,"SETTINGS & CONTROLS",Rect2(30,22,720,48),29)
	label_at(p,"Sound volume",Rect2(30,98,245,34),22)
	var volume=HSlider.new()
	volume.position=Vector2(285,98)
	volume.size=Vector2(425,40)
	volume.min_value=0
	volume.max_value=1
	volume.step=0.05
	volume.value=Progress.settings.volume
	p.add_child(volume)
	volume.value_changed.connect(func(value):Progress.settings.volume=value;Progress.save_game();play_sound("collect"))
	var reduced=CheckButton.new()
	reduced.text="Reduced motion"
	reduced.position=Vector2(28,167)
	reduced.size=Vector2(710,54)
	reduced.button_pressed=Progress.settings.reduced_motion
	reduced.add_theme_font_size_override("font_size",22)
	p.add_child(reduced)
	reduced.toggled.connect(func(value):Progress.settings.reduced_motion=value;Progress.save_game();apply_settings())
	var touch=CheckButton.new()
	touch.text="Always show touch controls"
	touch.position=Vector2(28,234)
	touch.size=Vector2(710,54)
	touch.button_pressed=Progress.settings.touch
	touch.add_theme_font_size_override("font_size",22)
	p.add_child(touch)
	touch.toggled.connect(func(value):Progress.settings.touch=value;Progress.save_game();apply_settings())
	label_at(p,"A/D or arrows: move · Space/W/Up: jump\nE/Enter: interact or next line · H: hint · Esc: pause\nEvery sound event also has a visible cue.",Rect2(30,310,720,105),19)
	button(p,"Back",Rect2(230,425,315,58),func():Progress.save_game();back.call(),true)

func apply_settings() -> void:
	if is_instance_valid(player):player.reduced_motion=bool(Progress.settings.reduced_motion)
	if is_instance_valid(campus):campus.reduced_motion=bool(Progress.settings.reduced_motion)
	if is_instance_valid(touch_root):touch_root.visible=bool(Progress.settings.touch) or input_touch or OS.has_feature("mobile")

func toast(text: String) -> void:
	toast_label.text=text
	toast_time=5
	toast_label.show()

func play_sound(id: String) -> void:
	if sounds.has(id) and float(Progress.settings.volume)>0:
		sound_player.stream=sounds[id]
		sound_player.volume_db=linear_to_db(float(Progress.settings.volume))
		sound_player.play()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		Progress.save_game()


func build_world_finish() -> void:
	var layer=CanvasLayer.new()
	layer.layer=5
	add_child(layer)
	var finish=ColorRect.new()
	finish.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish.mouse_filter=Control.MOUSE_FILTER_IGNORE
	finish_material=ShaderMaterial.new()
	finish_material.shader=load("res://shaders/storybook_finish.gdshader")
	finish.material=finish_material
	layer.add_child(finish)

func return_from_film() -> void:
	campus.build(true)
	player.position=Vector2(960,610)
	player.velocity=Vector2.ZERO
	player.right_bound=1550
	ambient.color=Color("edece1")
	show_title()
