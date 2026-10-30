extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const CampusScript = preload("res://scripts/campus.gd")
const GOALS = ["Read the Big Ideas Fair invitation in the school hallway.","Climb the garden books with Bark's double jump to recover your design.","Find the wandering plant and return it to the stump display.","Climb for the garden book base and the classroom pencil guide.","Bring your supplies to the classroom invention desk.","Assemble your paper-plane machine at the desk.","Test your invention and deliver the invitation to the fair board.","Big idea complete! Explore the campus and find its secrets."]
const TUTORIAL_GOALS = ["Walk right to meet Bark.","Jump over the low log. You can try as often as you like.","Jump, then press Jump again in the air for Bark's leafy lift!", "Walk to your notebook and interact with it.","Collect the bright leaf just ahead.","Ask Bark for a hint.","Interact with the practice plane for a gentle launch.","Watch your paper plane reach the target!"]
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
var shrinking_intro
var tutorial_double_baseline: int = 0
var jump_meter: Label
const BARK_NOTEBOOK_QUIPS = [
	"Bark: Aim for the clouds! Mark: The next platform will do.",
	"Bark: Try landing upside down! Mark: Feet first, please.",
	"Bark: I call this leaf-powered nonsense. Mark: Useful nonsense!",
	"Bark: Can we jump over tomorrow? Mark: One ledge at a time."
]
var soundscape
var objective_icon: TextureRect
var quest_ribbon
var step_label: Label
var toast_panel: Panel
var toast_age: float = 0.0
var modal_veil: ColorRect
var celebration
var flight_trail: Line2D
var quitting: bool = false
var quit_prompt: CanvasLayer
var notebook_button: Button
var hint_button: Button
var modal_back: Callable
var dialogue_count: Label
var whimsy_hud
var _hud_goal_signature: String = ""
var _hud_goal_pending: String = ""
var _idle_hint_goal: String = ""

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
	get_tree().auto_accept_quit=false
	configure_input()
	campus = CampusScript.new()
	add_child(campus)
	campus.build(true)
	player = PlayerScript.new()
	player.contact_shadow_enabled=false
	add_child(player)
	player.jumped.connect(on_player_jump)
	player.landed.connect(on_player_landed)
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
	flight_trail=Line2D.new()
	flight_trail.width=2.5
	flight_trail.default_color=Color(1,0.90,0.62,0.45)
	flight_trail.z_index=8
	add_child(flight_trail)
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
	shrinking_intro=load("res://scripts/shrinking_intro.gd").new()
	shrinking_intro.game=self
	add_child(shrinking_intro)
	soundscape=load("res://scripts/soundscape.gd").new()
	soundscape.game=self
	add_child(soundscape)
	Progress.settings_changed.connect(on_shared_settings_changed)
	Progress.save_status_changed.connect(on_save_status_changed)
	apply_settings()
	show_title()

func configure_input() -> void:
	var mapping={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E,KEY_ENTER],"hint":[KEY_H],"pause":[KEY_ESCAPE],"notebook":[KEY_N]}
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
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
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
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,Color("fff3d5") if primary else Color("203849"))
	b.add_theme_stylebox_override("normal",panel_style("203849" if primary else "fff5dc"))
	b.add_theme_stylebox_override("hover",panel_style("365c6d" if primary else "e7d198"))
	b.add_theme_stylebox_override("pressed",panel_style("1a313f" if primary else "d8bb73"))
	var focus_style=StyleBoxFlat.new()
	focus_style.bg_color=Color.TRANSPARENT
	focus_style.border_color=Color("edc872")
	focus_style.set_border_width_all(3)
	focus_style.set_corner_radius_all(18)
	b.add_theme_stylebox_override("focus",focus_style)
	if parent==hud or parent==touch_root or parent.get_parent()==hud:
		b.focus_mode=Control.FOCUS_NONE
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
	# Journal data remains available to the notebook and accessibility checks.
	# Its former full-width header and shortcut rows never paint over the world.
	var journal_data=Control.new()
	journal_data.name="JournalData"
	journal_data.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(journal_data)
	journal_data.hide()
	objective_icon=TextureRect.new()
	objective_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	objective_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	journal_data.add_child(objective_icon)
	zone_label=label_at(journal_data,"THE BIG IDEA",Rect2(0,0,730,24),16)
	objective=label_at(journal_data,"",Rect2(0,30,730,60),21)
	step_label=label_at(journal_data,"",Rect2(0,92,300,24),16)
	quest_ribbon=load("res://scripts/quest_ribbon.gd").new()
	quest_ribbon.size=Vector2(245,18)
	journal_data.add_child(quest_ribbon)
	counter=label_at(journal_data,"",Rect2(750,30,200,86),17)
	jump_meter=label_at(journal_data,"",Rect2(0,120,300,30),17)
	hint_button=button(journal_data,"Bark's hint  [H]",Rect2(0,180,240,50),request_hint)
	notebook_button=button(journal_data,"Notebook  [N]",Rect2(250,180,240,50),show_notebook)
	var skip=button(hud,"Skip tutorial",Rect2(0,0,180,50),finish_tutorial)
	skip.name="SkipTutorial"
	skip.hide()
	whimsy_hud=load("res://scripts/whimsy_hud.gd").new()
	whimsy_hud.controller=self
	hud.add_child(whimsy_hud)
	whimsy_hud.pause_requested.connect(show_pause)
	whimsy_hud.journal_requested.connect(show_notebook)
	touch_root=whimsy_hud.touch_root
	whimsy_hud.touch_buttons.left.button_down.connect(func():touches.left=true)
	whimsy_hud.touch_buttons.left.button_up.connect(func():touches.left=false)
	whimsy_hud.touch_buttons.right.button_down.connect(func():touches.right=true)
	whimsy_hud.touch_buttons.right.button_up.connect(func():touches.right=false)
	whimsy_hud.touch_buttons.jump.pressed.connect(jump_pressed)
	whimsy_hud.touch_buttons.use.pressed.connect(interact_pressed)
	prompt_panel=Panel.new()
	prompt_panel.position=Vector2(390,30)
	prompt_panel.size=Vector2(500,52)
	prompt_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_theme_stylebox_override("panel",hud_paper())
	hud.add_child(prompt_panel)
	prompt=label_at(prompt_panel,"",Rect2(16,10,468,32),18,"304f50")
	prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.hide()
	toast_panel=Panel.new()
	toast_panel.position=Vector2(370,28)
	toast_panel.size=Vector2(540,68)
	toast_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel",hud_paper())
	hud.add_child(toast_panel)
	toast_label=label_at(toast_panel,"",Rect2(18,12,504,44),18,"304f50")
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	toast_panel.hide()
	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	modal_veil=ColorRect.new()
	modal_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_veil.color=Color(0.07,0.13,0.17,0.34)
	modal_veil.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_veil.hide()
	overlay.add_child(modal_veil)
	celebration=load("res://scripts/celebration.gd").new()
	celebration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	celebration.hide()
	overlay.add_child(celebration)
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

func focus_action(prefix: String) -> void:
	if not is_instance_valid(modal):return
	for child in modal.get_children():
		if child is Button and child.text.begins_with(prefix):
			child.grab_focus()
			return

func current_goal() -> String:
	if mode=="tutorial":return TUTORIAL_GOALS[mini(tutorial_step,7)]
	var stage=int(Progress.data.stage)
	if stage==2 and Progress.data.plant:return "Return the plant you are carrying to the garden stump display."
	if stage==3:
		if Progress.data.books:return "Book base ready! Climb the classroom Pencil Express for the pencil guide."
		if Progress.data.pencil:return "Pencil ready! Climb the garden leaf ledges for the book base."
	return GOALS[clampi(stage,0,7)]

func close_modal() -> void:
	modal_back=Callable()
	if is_instance_valid(modal):
		overlay.remove_child(modal)
		modal.queue_free()
	modal=null
	if is_instance_valid(modal_veil):modal_veil.hide()
	busy=false
	player.suspended=false
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
	modal_veil.visible=mode in ["tutorial","campus"]
	player.suspended=mode in ["tutorial","campus"]
	overlay.add_child(modal)
	return modal

func show_title() -> void:
	mode="title"
	flight.clear()
	flight_trail.clear_points()
	hud.visible=false
	campus.build(true)
	for item in campus.objects:
		item.sprite.hide()
		item.label.hide()
	for ledge in campus.fun_ledges:ledge.hide()
	player.position=Vector2(925,610)
	player.velocity=Vector2.ZERO
	player.visual_scale=0.36
	player.facing=1
	player.pose_lock=0
	player.reset_jumps()
	campus.bark.position=Vector2(1125,610)
	campus.bark.scale=Vector2.ONE*0.31
	campus.bark.texture=Art.tex("bark_actions_cheer")
	var decoration=load("res://scripts/title_garden.gd").new()
	decoration.game=self
	decoration.z_index=2
	campus.add_child(decoration)
	campus.world_label("Small friends. Big possibilities.",Vector2(795,236),19)
	var p=open_modal(Rect2(48,42,602,638))
	label_at(p,"THE COMPLETE CAMPUS STORY · 3.7.0",Rect2(36,24,530,28),16,"977134")
	label_at(p,"MARK & BARK",Rect2(34,63,535,64),43)
	label_at(p,"THE BIG IDEA",Rect2(36,130,530,42),27,"977134")
	label_at(p,"A shrinking ray. Two tiny friends.\nA school full of GIANT possibilities!",Rect2(36,188,535,68),21)
	button(p,"Continue exploring" if Progress.data.completed else "Continue adventure" if Progress.tutorial_done else "Start adventure",Rect2(36,273,530,64),start_continue,true)
	button(p,"New adventure",Rect2(36,354,253,57),confirm_new)
	button(p,"Replay tutorial",Rect2(306,354,260,57),start_tutorial)
	button(p,"Settings & controls",Rect2(36,428,530,57),func():show_settings(show_title))
	button(p,"Watch the campus film",Rect2(36,500,530,53),func():cinema.begin(return_from_film))
	button(p,"All adventures",Rect2(36,563,530,43),func():Adventures.go(Adventures.HOME))
	label_at(p,"Touch: hold arrows · tap Jump twice · Use: interact" if input_touch or Progress.settings.touch else "A/D: move · Space twice: jump · E: use · N: notes · H: hint",Rect2(36,616,530,22),13)
	var save_state="Progress could not be saved. Keep this game open." if not Progress.last_save_ok else "Recovered your previous saved adventure." if Progress.recovered_backup else "Saved on this device · Fair complete" if Progress.data.completed else "Saved quest · Step "+str(int(Progress.data.stage)+1)+" / 7" if Progress.tutorial_done else "Start with a short, skippable tutorial"
	label_at(p,save_state,Rect2(36,247,530,22),15,"8b392b" if not Progress.last_save_ok else "53715b")
	focus_action("Continue" if Progress.tutorial_done else "Start adventure")
	camera.position=Vector2(640,360)
	camera.zoom=Vector2.ONE
	ambient.color=Color("edece1")
	player.enabled=false

func watch_film() -> void:
	cinema.begin(return_from_film)

func confirm_new() -> void:
	var p=open_modal(Rect2(330,190,620,330))
	modal_back=show_title
	label_at(p,"Start a new adventure?",Rect2(30,26,560,50),30)
	label_at(p,"This resets your current quest and discoveries. Your accessibility settings stay the same.",Rect2(30,95,560,95),22)
	button(p,"Keep my adventure",Rect2(30,220,260,65),show_title)
	button(p,"Start fresh",Rect2(320,220,270,65),func():Progress.reset_game();shrinking_intro.begin(start_tutorial),true)
	focus_action("Keep my adventure")

func start_continue() -> void:
	if Progress.tutorial_done:
		start_campus()
	else:
		shrinking_intro.begin(start_tutorial)

func start_tutorial() -> void:
	cancel_room_transition()
	close_modal()
	mode="tutorial"
	tutorial_step=0
	tutorial_jumped=false
	tutorial_seen_jump=false
	tutorial_double_baseline=player.double_jump_count
	player.visual_scale=0.24
	player.reset_jumps()
	campus.build(true)
	player.position=Vector2(120,605)
	player.velocity=Vector2.ZERO
	player.right_bound=1550
	hud.visible=true
	player.enabled=true
	idle_time=0
	camera.position=Vector2(640,360)
	say(["Mark|We're tiny! How will we get to the fair?","Bark|Small steps. Big jumps. And one extra leafy lift from me!","Mark|And our invention?","Bark|Still a very interesting first attempt. Let's practise our tiny adventure here."])
	update_hud()

func finish_tutorial() -> void:
	Progress.tutorial_done=true
	Progress.data.shrunken=true
	Progress.save_game()
	start_campus()

func start_campus() -> void:
	cancel_room_transition()
	close_modal()
	mode="campus"
	player.visual_scale=0.24
	player.reset_jumps()
	Progress.data.shrunken=true
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
	button(p,"Next" if input_touch else "Next  [E]",Rect2(912,183,210,50),next_dialogue,true)
	dialogue_count=label_at(p,"",Rect2(750,197,125,28),16,"977134")
	dialogue_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	refresh_dialogue()
	focus_action("Finish" if dialogue_lines.size()==1 else "Next")

func refresh_dialogue() -> void:
	var parts=String(dialogue_lines[dialogue_index]).split("|",true,1)
	dialogue_speaker.text=parts[0]
	dialogue_count.text=str(dialogue_index+1)+" / "+str(dialogue_lines.size())
	dialogue_text.text=parts[1] if parts.size()>1 else parts[0]
	for child in modal.get_children():
		if child is Button and (child.text.begins_with("Next") or child.text.begins_with("Finish")):
			child.text=("Finish" if dialogue_index==dialogue_lines.size()-1 else "Next")+("" if input_touch else "  [E]")
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
	if mode=="shrinking" and event is InputEventScreenTouch:
		input_touch=true
		shrinking_intro.skip_button.text="Skip intro"
		if event.pressed and Rect2(1030,15,220,48).has_point(event.position):
			shrinking_intro.finish()
			get_viewport().set_input_as_handled()
		return
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
		if event.pressed and not busy and mode in ["tutorial","campus"] and touch_root.is_visible_in_tree():
			if whimsy_hud.touch_rect("left").has_point(event.position):
				touch_fingers[event.index]="left"
			elif whimsy_hud.touch_rect("right").has_point(event.position):
				touch_fingers[event.index]="right"
			elif whimsy_hud.touch_rect("jump").has_point(event.position):
				jump_pressed()
				get_viewport().set_input_as_handled()
			elif whimsy_hud.touch_buttons.use.is_visible_in_tree() and whimsy_hud.touch_rect("use").has_point(event.position):
				interact_pressed()
				get_viewport().set_input_as_handled()
		elif not event.pressed:
			touch_fingers.erase(event.index)
		touches.left="left" in touch_fingers.values()
		touches.right="right" in touch_fingers.values()
		if touch_fingers.has(event.index):get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touch_fingers.has(event.index):
		var direction=touch_fingers[event.index]
		var region: Rect2=whimsy_hud.touch_rect(direction)
		if not region.grow(20).has_point(event.position):touch_fingers.erase(event.index)
		touches.left="left" in touch_fingers.values()
		touches.right="right" in touch_fingers.values()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		input_touch=false
		apply_settings()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:return
	if mode=="shrinking":
		if event.is_action_pressed("interact") or event.is_action_pressed("pause"):shrinking_intro.finish()
		get_viewport().set_input_as_handled()
		return
	if mode=="cinematic":
		if event.is_action_pressed("interact") or event.is_action_pressed("pause"):cinema.finish()
		get_viewport().set_input_as_handled()
		return
	if not room_transition.is_empty():
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if busy:
			if is_instance_valid(dialogue_text):dismiss_dialogue()
			elif modal_back.is_valid():modal_back.call()
			elif mode!="title":close_modal()
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
	elif event.is_action_pressed("notebook"):
		show_notebook()
		get_viewport().set_input_as_handled()

func jump_pressed() -> void:
	if not busy and mode in ["tutorial","campus"] and flight.is_empty():
		player.request_jump()

func _physics_process(delta: float) -> void:
	player.suspended=busy and mode in ["tutorial","campus"] and flight.is_empty()
	if is_instance_valid(campus.bark) and campus.bark.has_method("drive"):
		campus.bark.frozen=player.suspended or not room_transition.is_empty()
	clock+=delta
	if mode in ["title","cinematic","shrinking"]:
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
	if flight.is_empty() and not busy:framing_x+=clampf(player.velocity.x*0.12,-32,32)
	if not flight.is_empty() and flight.kind=="workshop" and not Progress.settings.reduced_motion:
		framing_x += minf(float(flight.t)*100.0,380.0)
	var target=campus.camera_target(framing_x,player.position.y if flight.is_empty() else 610.0,player.velocity.y<-80 and flight.is_empty())
	if Progress.settings.reduced_motion:
		camera.position=target
	else:
		camera.position.x=lerpf(camera.position.x,target.x,1-exp(-delta*5))
		camera.position.y=lerpf(camera.position.y,target.y,1-exp(-delta*12))
	var bounds: Vector2 = Vector2(0,1550) if mode=="tutorial" else campus.ROOM_BOUNDS[campus.room]
	camera.position.x = clampf(camera.position.x,bounds.x+640,bounds.y-640)
	campus.depth.camera_x = camera.position.x
	campus.foreground.camera_x = camera.position.x
	campus.scenery.camera_x = camera.position.x
	if is_instance_valid(campus.board):
		campus.board.angle=angle_choice
		campus.board.power=power_choice
	if not busy and flight.is_empty():
		idle_time+=delta
		if absf(player.velocity.x)>20:idle_time=0
		if idle_time>35 and _idle_hint_goal!=current_goal():
			_idle_hint_goal=current_goal()
			toast("Need a clue? Pause for Bark's hint, or press H.")
			idle_time=0
		if mode=="tutorial":
			update_tutorial()
		else:
			collect_nearby()
			update_checkpoint(delta)
	if player.position.y>900:
		restart_checkpoint()
	if is_instance_valid(campus.bark) and not busy:
		var previous_bark=campus.bark.position
		var follow_x=clampf(player.position.x-90*player.facing,bounds.x+40,bounds.y-40)
		if not (mode=="tutorial" and tutorial_step==0):
			campus.bark.position.x=lerpf(campus.bark.position.x,follow_x,1-exp(-delta*3))
			campus.bark.position.y=lerpf(campus.bark.position.y,player.position.y if not player.is_on_floor() else campus.support_y(campus.bark.position.x,player.position.y),1-exp(-delta*7))
		var support: float=campus.support_y(campus.bark.position.x,player.position.y)
		if player.is_on_floor() and absf(campus.bark.position.y-support)<2:campus.bark.position.y=support
		campus.bark.scale.x=0.20*player.facing
		if not busy and clock>bark_pose_until:
			var frames = ["bark_actions_walk_stride_a","bark_actions_walk_passing","bark_actions_walk_stride_b","bark_actions_walk_passing"]
			var walking = absf(campus.bark.position.x-follow_x)>15
			campus.bark.texture=Art.tex(frames[int(clock*6)%4] if walking else "bark_actions_idle")
			campus.bark.scale.y=0.20 if Progress.settings.reduced_motion or walking else 0.20*(1+sin(clock*1.8)*0.009)
		if campus.bark.has_method("drive") and not campus.bark.frozen:
			var bark_velocity=(campus.bark.position-previous_bark)/maxf(delta,.001)
			var bark_state="walk" if absf(bark_velocity.x)>18 else "idle"
			if not player.is_on_floor():bark_state="anticipate"
			campus.bark.drive(bark_state,player.is_on_floor(),bark_velocity,clock*6)
	update_flight(delta)
	if not busy:
		toast_time-=delta
		toast_age+=delta
	# One short paper message at a time, in a safe band away from both friends.
	place_hud_message(toast_panel)
	toast_panel.visible=toast_time>0 and not busy
	toast_label.visible=toast_panel.visible
	toast_panel.modulate.a=1.0 if Progress.settings.reduced_motion else minf(clampf(toast_age/0.12,0,1),clampf(toast_time/0.3,0,1))
	update_hud()

func update_tutorial() -> void:
	if player.position.x>390 and player.position.x<610 and player.position.y<575:
		tutorial_seen_jump=true
	if tutorial_step==0 and player.position.x>=265:
		tutorial_step=1
		say(["Bark|Hello, inventor! Next, jump over that little log.\nSpace or the Jump button will do it."])
	elif tutorial_step==1 and player.position.x>550 and tutorial_seen_jump:
		tutorial_step=2
		tutorial_double_baseline=player.double_jump_count
		say(["Bark|Nice landing! Now jump and press Jump AGAIN while you're in the air. I'll give you a leafy lift!","Mark|A double jump! That high book ledge looks much less high now."])
	elif tutorial_step==2 and player.double_jump_count>tutorial_double_baseline and player.position.y<480:
		tutorial_step=3
		toast("Double jump! Brilliant. Now find your notebook on the ground.")
	elif tutorial_step==4 and player.position.distance_to(Vector2(840,545))<95:
		tutorial_step=5
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
			campus.feedback.reward(item.pos,item.sprite.texture)
			Progress.collect_leaf(item.id)
			campus.refresh()
			play_sound("collect")
			# The small leaf counter celebrates the discovery without another banner.

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
	objective.text=current_goal()
	zone_label.text="TINY GARDEN TUTORIAL" if mode=="tutorial" else last_zone
	jump_meter.text="2 jumps ready  ◆ ◆" if player.is_on_floor() or player.jumps_used==0 else "1 leafy lift left  ◆" if player.jumps_used==1 else "Land to recharge"
	quest_ribbon.total=8 if mode=="tutorial" else 7
	quest_ribbon.step=tutorial_step if mode=="tutorial" else int(Progress.data.stage)
	step_label.text="LESSON "+str(mini(tutorial_step+1,8))+" / 8" if mode=="tutorial" else "COMPLETE" if Progress.data.completed else "STEP "+str(mini(int(Progress.data.stage)+1,7))+" / 7"
	var icons=["school_props_noticeboard","collectibles_notebook","school_props_plant","collectibles_books","school_props_desk","collectibles_pencil","collectibles_paper_plane","collectibles_science_rosette"]
	if mode=="tutorial":icons=["bark_actions_point","young_actions_jump","bark_actions_cheer","collectibles_notebook","collectibles_leaf_token","ui_parts_hint_bulb","collectibles_paper_plane","ui_parts_reward_check"]
	objective_icon.texture=Art.tex(icons[clampi(tutorial_step if mode=="tutorial" else int(Progress.data.stage),0,7)])
	if mode=="campus" and int(Progress.data.stage)==3 and Progress.data.books:objective_icon.texture=Art.tex("collectibles_pencil")
	counter.text="Learn at your pace\nNo lost discoveries" if mode=="tutorial" else "Leaves  "+str(Progress.data.leaves.size())+" / 6\nNotes   "+str(Progress.data.discoveries.size())+" / 2\nBark token  "+("Found!" if Progress.data.bark_token else "Hidden")
	hud.get_node("SkipTutorial").hide()
	hint_button.text="Bark's hint" if input_touch else "Bark's hint  [H]"
	notebook_button.text="Notebook" if input_touch else "Notebook  [N]"
	var touch_requested: bool=bool(Progress.settings.touch) or input_touch or OS.has_feature("mobile")
	var active: bool=not busy and flight.is_empty() and room_transition.is_empty()
	campus.feedback.focus_id=""
	var item: Dictionary=campus.nearest(player.position) if active else {}
	var ask_bark: bool=active and mode=="tutorial" and tutorial_step==5 and player.position.distance_to(campus.bark.position)<160
	var use_visible: bool=active and (ask_bark or not item.is_empty())
	var leaps: int=2 if player.is_on_floor() or player.jumps_used==0 else maxi(0,2-player.jumps_used)
	whimsy_hud.update_state(Progress.data.leaves.size(),6,leaps,touch_requested and active,use_visible)
	if ask_bark:
		prompt.text=("Use: " if touch_requested else "[E] ")+"Ask Bark for a hint"
	elif not item.is_empty():
		campus.feedback.focus_id=String(item.id)
		prompt.text=("Use: " if touch_requested else "[E] ")+String(item.title)
		if item.id in ["notebook","books","pencil"] and not player.is_on_floor():
			prompt.text="Land beside "+String(item.title)+", then "+("tap Use." if touch_requested else "press E.")
	else:
		prompt.text=""
	# Objectives appear once when they change. The full task is always in Notes.
	var signature: String=mode+":"+current_goal()
	if signature!=_hud_goal_signature:
		_hud_goal_signature=signature
		_hud_goal_pending=current_goal()
	if active and toast_time<=0 and not _hud_goal_pending.is_empty():
		toast(_hud_goal_pending)
		_hud_goal_pending=""
	prompt_panel.visible=active and not prompt.text.is_empty() and toast_time<=0
	if prompt_panel.visible:
		fit_hud_message(prompt_panel,prompt,prompt.text,500)
		place_hud_message(prompt_panel)

func interact_pressed() -> void:
	if busy or not flight.is_empty() or not mode in ["tutorial","campus"]:
		return
	if mode=="tutorial" and tutorial_step==5 and player.position.distance_to(campus.bark.position)<160:
		request_hint()
		return
	var item=campus.nearest(player.position)
	if item.is_empty():
		toast("Walk a little closer to a notebook, sign or invention.")
		return
	campus.feedback.pulse(item.pos+Vector2(0,-20))
	var texture: Texture2D=item.sprite.texture
	interact_object(item.id)
	if item.id in ["notebook","plant","books","pencil"] and Progress.data.get(item.id,false):
		campus.feedback.reward(item.pos,texture)

func interact_object(id: String) -> void:
	idle_time=0
	if mode=="tutorial":
		if id=="tutorial_notebook" and tutorial_step==3:
			tutorial_step=4
			player.show_pose("young_actions_notebook",1)
			say(["Mark|My notebook! Every invention starts with a question.","Bark|Mine starts with 'what happens if I poke this?'\nNow collect that lovely leaf."])
		elif id=="tutorial_plane" and tutorial_step==6:
			tutorial_step=7
			launch_tutorial()
		else:
			toast("Let's finish the current garden lesson first.")
		return
	if id in ["notebook","books","pencil"] and not player.is_on_floor():
		toast("Land beside the supply, then use it. Bark will help with your second jump!")
		return
	var stage=int(Progress.data.stage)
	match id:
		"invitation":
			if stage==0:
				Progress.advance(1)
				say(["Mark|Big Ideas Fair: bring an invention, a question, and a friend.","Bark|I launched your notebook onto the garden book tower. Try flapping your ears!","Mark|Or we could jump, then use your leafy lift.","Bark|Fine. The sensible ridiculous plan."])
			else:say(["Bark|The fair welcomes first attempts, second attempts, and friends. Especially tree friends."])
		"notebook":
			if stage<1:
				toast("Read the fair invitation first. It's on the school noticeboard.")
			else:
				Progress.data.notebook=true
				Progress.advance(2)
				player.show_pose("young_actions_notebook",1)
				campus.refresh()
				say(["Mark|A book base, a pencil guide, and a puff of wind. A paper-plane delivery machine!","Bark|I used the plant as a parachute. It refused to open.","Mark|Plants need a display, not flying lessons. Let's bring it back.","Bark|Agreed. Next time: a bigger plant."])
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
				say(["Mark|There. Back where it belongs.","Bark|Now bounce up the right-hand branches for the book base. The pencil is on the classroom skyway!","Mark|No throwing this time. Jump, leafy lift, land, repeat.","Bark|But throwing was my entire transport policy! The shortcut is open when you need it."])
			else:toast("This display is waiting for its potted plant. Find it farther right in the garden.")
		"books","pencil":
			if stage<3:toast("Help restore the garden display first.")
			else:
				Progress.data[id]=true
				play_sound("collect")
				if Progress.data.books and Progress.data.pencil:Progress.advance(4)
				Progress.save_game()
				campus.refresh()
				if id=="books":
					say(["Bark|Book base secured! Slide down on it like a sled?","Mark|We need it for the machine. We can drop safely and take the garden shortcut.","Bark|Responsible sled ownership. Fascinating."])
				else:
					say(["Bark|The pencil! We could pole-vault into the fair!","Mark|Or use it as a guide so our plane flies straight.","Bark|One tiny adventure at a time. Meet you at the desk!"])
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
		if tutorial_step==5:
			tutorial_step=6
			say(["Bark|Good inventors ask questions!\nWalk to the paper plane on the right and interact to launch it."])
		else:say(["Bark|"+TUTORIAL_GOALS[mini(tutorial_step,7)]+"\nThere is no hurry. We can try again."])
	else:
		var clues=["The hallway noticeboard is between the lockers and the reading nook.","Start on the low log at the garden entrance. Jump toward the book ledge above it, then press Jump again near the top of your first jump. Land on the books and use the notebook.","Pick up the plant farther right in the garden, then return it to the stump display on the left.","For books: climb the rightmost low garden log, double-jump left to the leaf ledge, then hop right to the high book shelf. For the pencil: enter the classroom, climb the low book ledge, double-jump to the pencil platform, then hop right. Land before using each item.","The invention desk is in the classroom on the far right. The garden shortcut can help.","At the desk, add the books, then the pencil, then load your plane.","Try the middle angle and medium power. I'll show you the flight path at the workshop.","Six leaves, two funny notebook pages, and one secret Bark token are waiting to be found!"]
		var stage=int(Progress.data.stage)
		if stage==2 and Progress.data.plant:clues[2]="You already have the plant! Return left to the stump display and use it."
		if stage==3 and Progress.data.books:clues[3]="Books secured! Take the shortcut to the classroom. Climb the low book ledge, double-jump onto the pencil bridge, then hop right to the pencil guide."
		if stage==3 and Progress.data.pencil:clues[3]="Pencil secured! Return to the garden. Climb the far-right low log, double-jump left onto the leaf ledge, then hop right to the high book shelf."
		show_prediction=true
		say(["Bark|"+clues[clampi(stage,0,7)]])

func show_notebook() -> void:
	if busy or mode=="title" or not flight.is_empty() or not room_transition.is_empty():return
	var p=open_modal(Rect2(255,135,770,480))
	label_at(p,"MARK'S NOTEBOOK",Rect2(30,25,710,42),30)
	label_at(p,current_goal(),Rect2(32,80,710,68),21)
	var checklist=["Design notebook","Garden display","Book base","Pencil guide"]
	var ready=[Progress.data.notebook,Progress.data.plant_restored,Progress.data.books,Progress.data.pencil]
	for i in range(4):
		label_at(p,("✓ " if ready[i] else "○ ")+checklist[i]+(" · Ready" if ready[i] else " · To find"),Rect2(32,163+i*38,710,36),22,"53715b" if ready[i] else "203849")
	var doodle: String=BARK_NOTEBOOK_QUIPS[posmod(player.double_jump_count,BARK_NOTEBOOK_QUIPS.size())]
	label_at(p,"Leaves "+str(Progress.data.leaves.size())+" / 6  ·  Funny pages "+str(Progress.data.discoveries.size())+" / 2  ·  Bark portrait: "+("Found" if Progress.data.bark_token else "Hidden")+"\n"+doodle+"\nDiscoveries and quest progress stay safe between retries.",Rect2(32,324,710,70),18)
	button(p,"Where next?",Rect2(32,405,260,55),func():close_modal();request_hint())
	button(p,"Back to exploring",Rect2(332,405,400,55),close_modal,true)
	focus_action("Back to exploring")

func show_workshop(focus_text: String = "") -> void:
	if is_instance_valid(campus.board):
		campus.board.angle=angle_choice
		campus.board.power=power_choice
	var p=open_modal(Rect2(135,140,1010,520))
	label_at(p,"THE BIG IDEA WORKSHOP",Rect2(28,20,920,45),30)
	var built=int(Progress.data.assembled)
	if built<3:
		var desc=["Place the book base. A sturdy idea needs a sturdy beginning.","Add the pencil guide. Give your plane a direction.","Load the paper plane. Bark will provide one very scientific puff."]
		label_at(p,desc[built],Rect2(34,89,590,110),24)
		var image=TextureRect.new()
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.texture=Art.tex(["collectibles_books","collectibles_pencil","collectibles_paper_plane"][built])
		image.position=Vector2(666,80)
		image.size=Vector2(285,280)
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.add_child(image)
		button(p,["Place books","Add pencil","Load plane"][built],Rect2(34,230,535,80),assemble_next,true)
		for i in range(3):
			component_card(p,["collectibles_books","collectibles_pencil","collectibles_paper_plane"][i],["Book base","Pencil guide","Paper plane"][i],Rect2(34+i*201,335,189,78),i<built)
		label_at(p,"Your pieces appear on the desk as you build.",Rect2(34,425,600,40),17)
	else:
		label_at(p,"Choose your angle",Rect2(32,85,450,36),22)
		for i in range(3):
			var title=["Low 25°","Middle 40°","High 55°"][i]
			var b=button(p,("✓ " if i==angle_choice else "")+title,Rect2(32+i*315,128,295,66),func():angle_choice=i;show_workshop("✓ "+title),i==angle_choice)
			b.tooltip_text="Launch angle preset"
		label_at(p,"Choose the strength of Bark's puff",Rect2(32,215,920,40),22)
		for i in range(3):
			var title=["Gentle","Medium","Strong"][i]
			button(p,("✓ " if i==power_choice else "")+title,Rect2(32+i*315,265,295,66),func():power_choice=i;show_workshop("✓ "+title),i==power_choice)
		label_at(p,"Selected: "+["Low 25°","Middle 40°","High 55°"][angle_choice]+" + "+["Gentle","Medium","Strong"][power_choice]+" puff. Unlimited retries.",Rect2(32,354,915,40),20)
		button(p,"Apply flight hint",Rect2(32,407,280,66),func():show_prediction=true;angle_choice=1;power_choice=1;close_modal();draw_prediction();toast("Bark: Middle angle + medium puff. Follow the golden arc."))
		button(p,"Test invention!",Rect2(646,407,310,66),launch_workshop,true)
	button(p,"Explore",Rect2(720,22,235,48),close_modal)
	focus_action(focus_text if not focus_text.is_empty() else ["Place books","Add pencil","Load plane","Test invention!"][mini(built,3)])

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
	flight_trail.clear_points()
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
	flight_trail.clear_points()
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
			flight_trail.clear_points()
			campus.depth.burst(Vector2(1370,425))
			plane.queue_free()
			play_sound("success")
			say(["Mark|It worked!","Bark|Of course! Now for my BIG demonstration—","Bark|...Ah. The supplies have gone on an adventure. Let's follow them."],finish_tutorial)
		return
	var pos=trajectory(float(flight.t),int(flight.angle),int(flight.power))
	var previous: Vector2=flight.previous
	plane.position=pos
	if not Progress.settings.reduced_motion:
		flight_trail.add_point(pos)
		if flight_trail.get_point_count()>14:flight_trail.remove_point(0)
	else:flight_trail.clear_points()
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
		flight_trail.clear_points()
		plane.queue_free()
		player.enabled=true
		play_sound("miss")
		say(["Bark|Excellent! We now know where the target isn't.","Mark|Let's adjust our angle or power. The plane is ready to try again."],show_workshop)

func complete_invention() -> void:
	flight.clear()
	flight_trail.clear_points()
	player.show_pose("young_actions_cheer",2.5)
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

func explore_after_ending() -> void:
	player.pose_lock=0
	celebration.hide()
	celebration.active=false
	close_modal()

func show_ending() -> void:
	celebration.begin()
	var p=open_modal(Rect2(235,130,810,490))
	label_at(p,"BIG IDEA COMPLETE",Rect2(35,25,735,58),37)
	label_at(p,"A ROSETTE FOR CURIOSITY & FRIENDSHIP",Rect2(35,181,730,25),15,"977134")
	label_at(p,"Your invitation has reached the fair!\nYou built, experimented, helped, and tried again.",Rect2(35,100,730,86),23)
	var image=TextureRect.new()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.texture=Art.tex("collectibles_science_rosette")
	image.position=Vector2(560,205)
	image.size=Vector2(175,175)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(image)
	label_at(p,"Leaf discoveries: "+str(Progress.data.leaves.size())+" / 6\nFunny notebook pages: "+str(Progress.data.discoveries.size())+" / 2\nBark's secret token: "+("Found!" if Progress.data.bark_token else "Still waiting")+"\nInvention tests: "+str(Progress.data.attempts),Rect2(35,215,530,158),23)
	button(p,"Explore the campus",Rect2(35,400,355,62),explore_after_ending,true)
	button(p,"Play again",Rect2(420,400,350,62),func():Progress.reset_game();shrinking_intro.begin(start_tutorial))
	modal_back=explore_after_ending
	focus_action("Explore the campus")
	toast("A science rosette for curiosity, friendship, and your big idea!")

func show_pause() -> void:
	if mode=="title" or not flight.is_empty() or (busy and is_instance_valid(dialogue_text)):return
	var p=open_modal(Rect2(390,150,500,455))
	label_at(p,"A LITTLE BREATHER",Rect2(25,22,450,50),29)
	button(p,"Continue",Rect2(30,95,440,60),close_modal,true)
	button(p,"Restart checkpoint",Rect2(30,173,440,60),restart_checkpoint)
	button(p,"Settings & controls",Rect2(30,250,440,60),func():show_settings(show_pause))
	button(p,"Save & title screen",Rect2(30,329,440,60),func():Progress.save_game();show_title())
	label_at(p,"Retries keep your quest and discoveries.",Rect2(30,409,440,28),17)
	var tools=Panel.new()
	tools.position=Vector2(-320,0)
	tools.size=Vector2(300,455)
	tools.add_theme_stylebox_override("panel",panel_style("e6eddc"))
	p.add_child(tools)
	label_at(tools,"POCKET TOOLS",Rect2(24,24,252,38),23,"53715b")
	button(tools,"Notebook",Rect2(20,95,260,60),func():close_modal();show_notebook())
	button(tools,"Bark's hint",Rect2(20,173,260,60),func():close_modal();request_hint())
	if mode=="tutorial":
		button(tools,"Skip tutorial",Rect2(20,251,260,60),func():close_modal();finish_tutorial())
	label_at(tools,"N · Notebook\nH · Bark's hint\nSpace twice · Leafy lift",Rect2(24,337,252,90),17,"53715b")
	var details=Panel.new()
	details.position=Vector2(520,0)
	details.size=Vector2(300,455)
	details.add_theme_stylebox_override("panel",panel_style("f5edda"))
	p.add_child(details)
	label_at(details,"OUR LITTLE ADVENTURE",Rect2(22,24,256,55),21,"53715b")
	var goal_label=label_at(details,current_goal(),Rect2(22,95,256,150),20)
	goal_label.name="PauseObjective"
	goal_label.clip_text=true
	# Reapply after font/theme minimum sizes settle so long goals wrap inside
	# the paper sidecard instead of retaining their first unwrapped width.
	goal_label.size=Vector2(256,150)
	goal_label.set_deferred("size",Vector2(256,150))
	label_at(details,counter.text+"\n\n"+step_label.text,Rect2(22,275,256,145),18)
	focus_action("Continue")

func restart_checkpoint() -> void:
	cancel_room_transition()
	close_modal()
	flight.clear()
	prediction.clear_points()
	if is_instance_valid(plane):plane.queue_free()
	player.velocity=Vector2.ZERO
	player.reset_jumps()
	player.position=Vector2(120 if mode=="tutorial" else checkpoint,605)
	player.enabled=true
	if mode=="campus":sync_room()
	toast("A fresh start nearby. Your discoveries are safe.")

func show_settings(back: Callable) -> void:
	var p=open_modal(preload("res://scripts/shared_settings.gd").MENU_RECT)
	modal_back=back
	var content=preload("res://scripts/shared_settings.gd").new();content.done=back;p.add_child(content)

func on_shared_settings_changed(_key,_value) -> void:
	apply_settings()

func on_save_status_changed(ok) -> void:
	if not ok and mode in ["tutorial","campus"]:toast("Progress could not be saved. Your adventure is still open. Try again in Settings.")

func apply_settings() -> void:
	if is_instance_valid(player):
		player.reduced_motion=bool(Progress.settings.reduced_motion)
		if player.reduced_motion and is_instance_valid(player.ghost):
			player.ghost.hide()
			player.sprite.modulate.a=1
	if is_instance_valid(campus):campus.reduced_motion=bool(Progress.settings.reduced_motion)
	if is_instance_valid(touch_root):touch_root.visible=(bool(Progress.settings.touch) or input_touch or OS.has_feature("mobile")) and not busy and flight.is_empty() and room_transition.is_empty()

func hud_paper() -> StyleBoxFlat:
	var paper=panel_style("f5edda")
	paper.border_color=Color("a6b994")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(15)
	paper.shadow_color=Color(0.10,0.22,0.22,0.15)
	paper.shadow_size=4
	paper.shadow_offset=Vector2(0,3)
	return paper

func fit_hud_message(panel: Panel, text_label: Label, value: String, width: float) -> void:
	width=minf(width,maxf(260.0,get_viewport_rect().size.x-360.0))
	var measured: Vector2=Art.font.get_multiline_string_size(value,HORIZONTAL_ALIGNMENT_CENTER,width-36,18)
	panel.size=Vector2(width,clampf(measured.y+26,52,150))
	text_label.position=Vector2(18,12)
	text_label.size=panel.size-Vector2(36,24)
	text_label.text=value

func place_hud_message(panel: Panel) -> void:
	var viewport: Vector2=get_viewport_rect().size
	var center_x: float=(viewport.x-panel.size.x)*0.5
	var lower_y: float=maxf(150.0,viewport.y-172.0-panel.size.y)
	var actors: Array[Rect2]=[]
	for actor in [player,campus.bark]:
		if is_instance_valid(actor):
			var at: Vector2=actor.get_global_transform_with_canvas().origin
			actors.append(Rect2(at-Vector2(74,170),Vector2(148,185)))
	# Try quiet upper and lower bands, then their corners. Message cards never
	# occupy the movement/jump controls and move aside for either friend's face.
	var candidates: Array[Vector2]=[
		Vector2(center_x,28),Vector2(center_x,lower_y),
		Vector2(190,28),Vector2(viewport.x-panel.size.x-90,28),
		Vector2(24,lower_y),Vector2(viewport.x-panel.size.x-24,lower_y)
	]
	var persistent: Array=whimsy_hud.persistent_rects()
	for candidate in candidates:
		var rect: Rect2=Rect2(candidate,panel.size)
		if not Rect2(Vector2.ZERO,viewport).encloses(rect):continue
		var clear: bool=true
		for actor in actors:
			if rect.grow(10).intersects(actor):clear=false
		for item in persistent:
			if rect.grow(6).intersects(item):clear=false
		if clear:
			panel.position=candidate
			return
	panel.position=Vector2(center_x,28)

func toast(text: String) -> void:
	toast_time=clampf(2.5+text.length()/28.0,4,9)
	fit_hud_message(toast_panel,toast_label,text,540)
	place_hud_message(toast_panel)
	toast_age=0
	toast_panel.visible=not busy
	toast_label.visible=not busy

func play_sound(id: String, pitch: float = 1.0) -> void:
	if sounds.has(id) and float(Progress.settings.volume)>0:
		sound_player.stream=sounds[id]
		sound_player.pitch_scale=pitch
		sound_player.volume_db=linear_to_db(float(Progress.settings.volume))
		sound_player.play()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(player):
		Input.action_release("left")
		Input.action_release("right")
		touch_fingers.clear()
		touches.left=false
		touches.right=false
		player.axis=0
		if mode in ["tutorial","campus"] and not busy and flight.is_empty() and room_transition.is_empty():show_pause()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()


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


func on_player_jump(is_second: bool) -> void:
	play_sound("jump",1.18 if is_second else 1.0)
	if is_second:
		campus.bark.texture=Art.tex("bark_actions_cheer")
		bark_pose_until=clock+0.9
		# Keep the cheerful pose and sound; Bark's longer jokes live in Notes.


func on_player_landed(at: Vector2, strength: float) -> void:
	if mode not in ["tutorial","campus"]:return
	campus.land_on_ledge(at,strength)

func component_card(parent: Node, asset: String, text: String, rect: Rect2, complete: bool) -> void:
	var card=Panel.new()
	card.position=rect.position
	card.size=rect.size
	card.add_theme_stylebox_override("panel",panel_style("e3edd6" if complete else "fff5dc"))
	parent.add_child(card)
	var icon=TextureRect.new()
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.texture=Art.tex(asset)
	icon.position=Vector2(10,14)
	icon.size=Vector2(45,45)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)
	label_at(card,text,Rect2(62,15,116,24),15)
	label_at(card,"Ready ✓" if complete else "To add",Rect2(62,43,116,24),14,"53715b" if complete else "977134")


func request_quit() -> void:
	if quitting or (is_instance_valid(quit_prompt) and not quit_prompt.is_queued_for_deletion()):return
	if not preload("res://scripts/save_exit.gd").save_all():
		quit_prompt=preload("res://scripts/save_exit.gd").new();quit_prompt.retry=request_quit;quit_prompt.quit_anyway=finish_quit;add_child(quit_prompt);return
	await finish_quit()

func finish_quit() -> void:
	quitting=true;busy=true
	player.enabled=false
	player.suspended=true
	sound_player.stop()
	sound_player.stream=null
	await soundscape.drain()
	get_tree().quit()
