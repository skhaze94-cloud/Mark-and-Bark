extends Node

var root: Window

var game
var failures: Array[String] = []
var passed: Array[String] = []
var original_save: String = ""
var had_save: bool = false
var screenshots: bool = false

func _ready() -> void:
	root=get_tree().root
	call_deferred("run")

func check(condition: bool, name: String) -> void:
	if condition:
		passed.append(name)
		print("PASS: "+name)
	else:
		failures.append(name)
		push_error("FAIL: "+name)

func ticks(count: int = 2) -> void:
	for i in range(count):await get_tree().physics_frame

func dismiss() -> void:
	if game.busy and is_instance_valid(game.dialogue_text):game.dismiss_dialogue()
	await ticks()

func walk_to(x: float, limit: int = 1200) -> void:
	var action="right" if x>game.player.position.x else "left"
	Input.action_press(action)
	var count=0
	while absf(game.player.position.x-x)>22 and count<limit:
		await get_tree().physics_frame
		if game.busy and is_instance_valid(game.dialogue_text):game.dismiss_dialogue()
		if (action=="right" and game.player.position.x>=x) or (action=="left" and game.player.position.x<=x):break
		count+=1
	Input.action_release(action)
	await ticks(8)
	check(count<limit,"Walk reaches "+str(x))

func press_key(code: int) -> void:
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.pressed=true
	Input.parse_input_event(e)
	await ticks(2)
	e=InputEventKey.new()
	e.physical_keycode=code
	e.pressed=false
	Input.parse_input_event(e)
	await ticks(2)

func capture(name: String) -> void:
	if not screenshots:return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	if image and not image.is_empty():image.save_png("res://test_output/"+name+".png")

func run() -> void:
	await get_tree().process_frame
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	had_save=FileAccess.file_exists(Progress.SAVE_PATH)
	if had_save:original_save=FileAccess.get_file_as_string(Progress.SAVE_PATH)
	Progress.save_enabled=false
	Progress.reset_game(false)
	Progress.tutorial_done=false
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await ticks(5)
	check(game.mode=="title","Title scene loads")
	check(game.player.visual_scale==0.36 and game.campus.bark.texture==Art.tex("bark_actions_cheer"),"Title stages both friends with their original identities")
	check(game.player.ghost.offset==game.player.sprite.offset and game.player.ghost.position==game.player.sprite.position,"Pose crossfades share the supplied character foot pivot")
	var hud_buttons: Array[Button]=[]
	collect_buttons(game.hud,hud_buttons)
	check(hud_buttons.all(func(b):return b.focus_mode==Control.FOCUS_NONE),"Gameplay buttons cannot steal keyboard jump focus")
	var menu_buttons: Array[Button]=[]
	collect_buttons(game.modal,menu_buttons)
	check(menu_buttons.all(func(b):return b.focus_mode==Control.FOCUS_ALL),"Menus retain keyboard focus navigation")
	check(game.soundscape.music.stream!=null and game.soundscape.garden.stream!=null,"Original music and garden soundscape are bundled")
	check(game.soundscape.music.stream.loop_end>350000 and game.soundscape.music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Music has an explicit seamless forward loop")
	var volume_before: float=Progress.settings.volume
	Progress.settings.volume=0
	game.soundscape._process(0)
	check(game.soundscape.music.stream_paused and game.soundscape.garden.stream_paused,"Master mute silences music and ambience immediately")
	Progress.settings.volume=volume_before
	Progress.settings.music=false
	game.soundscape._process(0)
	check(game.soundscape.music.stream_paused,"Background music can be disabled independently")
	Progress.settings.music=true
	game.soundscape._process(0)
	check(Art.tex("workshop_hub_v2").get_width()>1200,"Detailed workshop backdrop is bundled")
	check(Art.tex("school_door_v2").get_image().detect_alpha()!=Image.ALPHA_NONE,"Doorway sprite has genuine transparency")
	check(game.campus.depth!=null and game.campus.foreground.z_index>game.player.z_index,"Depth scenery and foreground layers are separate")
	await capture("01_title")
	var before_intro=JSON.stringify(Progress.data)
	game.start_continue()
	await ticks(2)
	check(game.mode=="shrinking" and not game.player.enabled,"New adventure starts the shrinking-ray story")
	game.shrinking_intro.age=6.8
	game.shrinking_intro.update_story()
	check(is_equal_approx(game.player.visual_scale,0.24) and game.campus.bark.scale.x<0.21,"Ray visibly shrinks both friends around their foot pivots")
	check(JSON.stringify(Progress.data)==before_intro,"Watching the ray does not change inventory or quest")
	await press_key(KEY_E)
	await dismiss()
	check(game.mode=="tutorial" and Progress.data.shrunken,"Keyboard skips the ray into a miniature tutorial")
	Progress.settings.reduced_motion=true
	game.shrinking_intro.begin(game.start_tutorial)
	game.shrinking_intro.age=5.6
	game.shrinking_intro.update_story()
	check(game.player.visual_scale==0.24 and game.camera.zoom==Vector2.ONE,"Reduced-motion ray uses a calm static size reveal")
	game.shrinking_intro.age=14.99
	await ticks(3)
	await dismiss()
	check(game.mode=="tutorial" and not game.shrinking_intro.running,"Ray finishes automatically and restores playable tutorial")
	game.shrinking_intro.begin(game.start_tutorial)
	var intro_touch=InputEventScreenTouch.new()
	intro_touch.position=Vector2(1140,38)
	intro_touch.index=0
	intro_touch.pressed=true
	root.push_input(intro_touch,true)
	await ticks(2)
	check(not game.shrinking_intro.running and game.mode=="tutorial","Touch skips ray intro through its visible control")
	intro_touch=InputEventScreenTouch.new()
	intro_touch.position=Vector2(1140,38)
	intro_touch.index=0
	intro_touch.pressed=false
	root.push_input(intro_touch,true)
	await dismiss()
	Progress.settings.reduced_motion=false
	game.return_from_film()
	for id in ["invention_board_v3","reading_nook_v3","canopy_v3"]:
		check(Art.tex(id).get_image().detect_alpha()!=Image.ALPHA_NONE,"Cinematic cutout has transparency: "+id)
	var before_film=JSON.stringify(Progress.data)
	game.cinema.begin(game.return_from_film)
	await ticks(3)
	check(game.mode=="cinematic" and not game.player.enabled,"Film disables adventure controls")
	check(game.campus.scenery.planes.size()>=10,"Furniture and foliage have independent depth planes")
	var anchored: Array[Vector2]=[]
	game.campus.scenery.camera_x=4000
	game.campus.scenery._process(0)
	for piece in game.campus.scenery.planes:anchored.append(piece.sprite.position)
	game.campus.scenery.camera_x=5000
	game.campus.scenery._process(0)
	var stable=true
	for i in range(anchored.size()):stable=stable and anchored[i]==game.campus.scenery.planes[i].sprite.position
	check(stable,"Furniture and canopy anchors do not follow camera movement")
	game.campus.depth.camera_x=5000
	game.campus._process(0)
	var painted_stable=true
	for backdrop in game.campus.backgrounds:painted_stable=painted_stable and backdrop.sprite.position.x==backdrop.base
	check(painted_stable,"Flattened rooms stay aligned with fixed props")
	check(is_instance_valid(game.campus.board) and game.campus.board.global_position+game.campus.board.TARGET==Vector2(5050,290),"One live board contains the original delivery target")
	check(not game.campus.object("fair_target").sprite.visible,"Duplicate fair board sprite is removed")
	check(game.campus.support_y(3290,490)==490 and game.campus.support_y(3290,460)==490 and game.campus.support_y(4430,605)==610,"Character shadows use the nearest supporting platform or floor")
	var assembly_before=int(Progress.data.assembled)
	Progress.data.assembled=2
	game.campus.board.angle=2
	game.campus.board.power=2
	game.campus.board._process(0)
	check("2 / 3" in game.campus.board.status.text and "55" in game.campus.board.status.text and "Strong" in game.campus.board.status.text,"Live board updates assembly and launch settings")
	Progress.data.assembled=assembly_before
	for time in [2.0,9.0,16.0,23.0]:
		game.cinema.age=time
		game.cinema.update_shot()
		await ticks(2)
	check(game.cinema.shot_index==3 and JSON.stringify(Progress.data)==before_film,"Four film shots preserve quest progress")
	await press_key(KEY_E)
	check(game.mode=="title" and not game.cinema.running and game.camera.zoom==Vector2.ONE,"Keyboard skips film and restores title camera")
	Progress.settings.reduced_motion=true
	game.cinema.begin(game.return_from_film)
	game.cinema.age=16
	game.cinema.update_shot()
	check(game.camera.zoom==Vector2.ONE and game.camera.position.x==4650,"Reduced-motion film avoids camera movement and zoom")
	game.cinema.age=27.99
	await ticks(3)
	check(game.mode=="title" and not game.cinema.running,"Film ends automatically")
	game.cinema.begin(game.return_from_film)
	var film_touch=InputEventScreenTouch.new()
	film_touch.index=0
	film_touch.position=Vector2(1140,32)
	film_touch.pressed=true
	root.push_input(film_touch,true)
	await ticks(2)
	check(game.mode=="title" and not game.cinema.running,"Touch skips film through visible control")
	film_touch=InputEventScreenTouch.new()
	film_touch.index=0
	film_touch.position=Vector2(1140,32)
	film_touch.pressed=false
	root.push_input(film_touch,true)
	Progress.settings.reduced_motion=false
	game.cinema.begin(game.start_tutorial)
	game.cinema.finish()
	await dismiss()
	check(game.mode=="tutorial" and game.tutorial_step==0,"Opening film hands off to tutorial")
	game.start_tutorial()
	await dismiss()
	check(game.tutorial_step==0,"Tutorial starts with walking")
	await walk_to(310)
	await dismiss()
	check(game.tutorial_step==1,"Tutorial walking gate advances")
	await walk_to(430)
	await press_key(KEY_SPACE)
	await walk_to(680)
	check(game.tutorial_step==2,"Real jump clears tutorial log")
	await dismiss()
	await ticks(50)
	await press_key(KEY_SPACE)
	await ticks(24)
	await press_key(KEY_SPACE)
	await ticks(3)
	check(game.tutorial_step==3 and game.player.jumps_used==2,"Tutorial teaches a real midair leafy double jump")
	await walk_to(790)
	await ticks(70)
	await walk_to(680)
	check(game.campus.feedback.focus_id=="tutorial_notebook","Nearby interaction cue identifies the notebook")
	await press_key(KEY_E)
	await dismiss()
	check(game.tutorial_step==4,"Keyboard interacts with notebook")
	await walk_to(855)
	check(game.tutorial_step==5,"Tutorial leaf auto-collects")
	await press_key(KEY_H)
	await dismiss()
	check(game.tutorial_step==6,"Hint advances tutorial")
	await walk_to(1080)
	await press_key(KEY_E)
	await ticks(110)
	await dismiss()
	await dismiss()
	check(Progress.tutorial_done and game.mode=="campus","Practice flight completes tutorial and opens campus")
	game.start_tutorial()
	await dismiss()
	game.finish_tutorial()
	await dismiss()
	check(game.mode=="campus" and game.player.enabled,"Skip tutorial unlocks main gameplay")
	await ticks(10)
	var second_count=game.player.double_jump_count
	await press_key(KEY_SPACE)
	await ticks(24)
	await press_key(KEY_SPACE)
	check(game.player.jumps_used==2 and game.player.double_jump_count==second_count+1,"Keyboard grants one extra jump in midair")
	var v_before: float=game.player.velocity.y
	await press_key(KEY_SPACE)
	check(game.player.jumps_used==2 and game.player.velocity.y>v_before,"A third airborne press cannot add another jump")
	await ticks(95)
	check(game.player.is_on_floor() and game.player.jumps_used==0,"Landing recharges both jumps")
	await press_key(KEY_SPACE)
	await ticks(10)
	game.show_pause()
	var paused_at: Vector2=game.player.position
	var paused_velocity: Vector2=game.player.velocity
	await ticks(15)
	check(game.player.position==paused_at and game.player.velocity==paused_velocity and game.player.suspended,"Pause freezes a real airborne jump without losing velocity")
	check(game.modal_veil.visible and game.soundscape.music.stream_paused,"Pause has a readable backdrop and pauses the music")
	game.close_modal()
	await ticks(4)
	check(game.player.position!=paused_at and not game.player.suspended,"Closing pause resumes the same jump")
	await ticks(95)
	check(is_equal_approx(game.player.sprite.scale.y,0.24) or absf(game.player.sprite.scale.y-0.24)<0.01,"Tiny character size remains stable while standing and moving")
	# A real walk off a book ledge retains an air rescue after coyote time.
	game.player.position=Vector2(1130,520)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	await ticks(5)
	Input.action_press("right")
	await ticks(20)
	Input.action_release("right")
	await ticks(10)
	await press_key(KEY_SPACE)
	check(game.player.jumps_used==2 and game.player.velocity.y<0,"Walking off a ledge leaves one forgiving rescue jump")
	game.player.position=Vector2(700,605)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	await ticks(12)
	await walk_to(810)
	await press_key(KEY_E)
	await dismiss()
	check(int(Progress.data.stage)==1,"Fair invitation starts quest")
	check(game.quest_ribbon.step==1 and game.quest_ribbon.total==7 and "2 / 7" in game.step_label.text,"Quest ribbon and numbered objective advance together")
	check(game.objective_icon.texture==Art.tex("collectibles_notebook"),"Objective pictogram matches the next story task")
	await capture("02_hallway")
	await walk_to(2090)
	check(game.campus.room==1 and game.transitions_completed>=1,"Walking off hallway enters a separate garden room")
	check(game.camera.position.x>=2340,"Garden camera excludes the hallway")
	check(game.campus.nearest(Vector2(2150,610)).get("id", "")!="notebook","Design cannot be picked up from the ground")
	var quest_lifts=game.player.double_jump_count
	await leap_to(2090,550)
	await leap_to(2150,290)
	check(game.player.double_jump_count>quest_lifts,"Main design route uses Bark double jump")
	await press_key(KEY_E)
	await dismiss()
	check(Progress.data.notebook and int(Progress.data.stage)==2,"Scattered notebook recovered")
	await walk_to(2840)
	await press_key(KEY_E)
	check(Progress.data.plant,"Misplaced plant collected")
	await walk_to(2320)
	await press_key(KEY_E)
	await dismiss()
	check(Progress.data.plant_restored and int(Progress.data.stage)==3,"Plant restoration advances quest and opens shortcut")
	await capture("03_garden")
	await walk_to(3290)
	check(game.campus.nearest(Vector2(3290,610)).get("id", "")!="books","Book base cannot be picked up from the ground")
	await leap_to(3290,490)
	await leap_to(3135,240)
	await leap_to(3290,190)
	await press_key(KEY_E)
	await dismiss()
	check(Progress.data.books,"Required high book base is reachable by platforming")
	await walk_to(3630)
	await ticks(70)
	await press_key(KEY_E)
	await ticks(65)
	check(game.campus.room==2 and game.player.position.x>4200,"Unlocked garden shortcut reaches workshop")
	await walk_to(4720)
	check(game.campus.nearest(Vector2(5310,610)).get("id", "")!="pencil","Pencil cannot be picked up from the ground")
	await leap_to(4720,470)
	await leap_to(4950,250)
	await leap_to(5310,260)
	await press_key(KEY_E)
	await dismiss()
	check(Progress.data.pencil and int(Progress.data.stage)==4,"High classroom pencil completes supply list")
	await ticks(80)
	await walk_to(4430)
	await press_key(KEY_E)
	check(int(Progress.data.stage)==5 and game.busy,"Workshop opens after supplies")
	game.assemble_next()
	await ticks(2)
	var card_icons: Array[TextureRect]=[]
	collect_textures(game.modal,card_icons)
	check(card_icons.size()>=4 and card_icons.all(func(t):return t.size.x<=285 and t.size.y<=280),"Assembly art and component icons stay inside their intended cards")
	game.assemble_next()
	game.assemble_next()
	await ticks(3)
	check(int(Progress.data.assembled)==3 and int(Progress.data.stage)==6,"All assembly steps persist")
	check(game.modal_veil.visible and game.player.suspended,"Workshop keeps the world safely still during assembly")
	await capture("04_workshop")
	game.angle_choice=0
	game.power_choice=0
	game.launch_workshop()
	await ticks(10)
	check(game.flight_trail.get_point_count()>0,"Test plane receives a restrained golden flight trail")
	await ticks(210)
	check(not Progress.data.completed and game.busy,"Miss returns plane with a retry dialogue")
	await dismiss()
	check(game.busy and int(Progress.data.assembled)==3,"Miss reopens assembled workshop")
	game.close_modal()
	game.request_hint()
	await dismiss()
	check(game.show_prediction,"Hint enables predicted trajectory")
	game.angle_choice=1
	game.power_choice=1
	game.launch_workshop()
	await ticks(160)
	check(Progress.data.completed and int(Progress.data.stage)==7,"Reliable middle-angle medium-power solution hits target")
	check(game.flight_trail.get_point_count()==0,"Successful delivery clears its temporary flight trail")
	await dismiss()
	check(game.busy,"Ending summary opens")
	check(game.celebration.active and game.celebration.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Ending confetti frames the summary without blocking buttons")
	var ending_art: Array[TextureRect]=[]
	collect_textures(game.modal,ending_art)
	check(ending_art.size()==1 and ending_art[0].size==Vector2(175,175),"Science rosette stays inside the ending panel")
	await capture("05_ending")
	game.close_modal()
	check(game.player.enabled,"Post-ending exploration remains available")
	# Climb the new routes with input and collision, rather than teleporting to rewards.
	game.player.position=Vector2(990,605)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await ticks(10)
	await leap_to(1060,520)
	var book_ledge=game.campus.fun_ledges.filter(func(ledge):return ledge.position==Vector2(960,520))[0]
	check(book_ledge.impact_age<0.3 and book_ledge.position==Vector2(960,520),"Landing feedback lights a book edge without moving its collider")
	await leap_to(1300,405)
	await leap_to(1545,285)
	check("leaf_1" in Progress.data.leaves,"High book skyway rewards real platforming")
	await press_key(KEY_SPACE)
	await ticks(23)
	await press_key(KEY_SPACE)
	await ticks(25)
	var screen_feet: Vector2=game.get_viewport().get_canvas_transform()*game.player.position
	check(game.camera.position.y<230 and screen_feet.y>230 and screen_feet.y<420,"Camera rises to keep high-route double jumps visible")
	await ticks(80)
	game.player.position=Vector2(2500,425)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await ticks(10)
	await leap_to(2500,255)
	await press_key(KEY_E)
	await dismiss()
	check("doodle_1" in Progress.data.discoveries,"High garden notebook is reachable and interactable")
	await leap_to(2830,250)
	await press_key(KEY_E)
	await dismiss()
	check(Progress.data.bark_token,"Bark token rewards the higher leaf-top route")
	await leap_to(3135,240)
	check("leaf_4" in Progress.data.leaves,"Leaf-top gap is safely crossed using double jump")
	game.player.position=Vector2(4690,605)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await ticks(10)
	await leap_to(4720,470)
	await leap_to(4950,250)
	await leap_to(5310,260)
	check("leaf_6" in Progress.data.leaves,"Workshop pencil express reaches its high reward")
	game.player.position=Vector2(4490,605)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await ticks(12)
	var count=Progress.data.leaves.size()
	Progress.collect_leaf("leaf_1")
	Progress.collect_leaf("leaf_1")
	check(Progress.data.leaves.count("leaf_1")==1,"Duplicate leaf collection is prevented")
	game.interact_object("doodle_2")
	await dismiss()
	check("doodle_2" in Progress.data.discoveries,"Optional notebook discovery records after ending")
	game.interact_object("bark_token")
	await dismiss()
	check(Progress.data.bark_token,"Optional Bark token records")
	Progress.settings.touch=true
	game.apply_settings()
	check(game.touch_root.visible,"Touch controls can be enabled")
	game.player.position=Vector2(4490,605)
	await ticks(8)
	var before=game.player.position.x
	var e=InputEventScreenTouch.new()
	e.index=0
	e.position=game.whimsy_hud.touch_rect("right").get_center()
	e.pressed=true
	root.push_input(e,true)
	await ticks(20)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=game.whimsy_hud.touch_rect("right").get_center()
	e.pressed=false
	root.push_input(e,true)
	await ticks(6)
	check(game.player.position.x>before+15,"Screen touch holds right movement and releases")
	check(not game.touches.right,"Touch release clears movement")
	# Exercise touch Jump via its actual GUI signal path.
	await ticks(30)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=game.whimsy_hud.touch_rect("jump").get_center()
	e.pressed=true
	root.push_input(e,true)
	await ticks(2)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=game.whimsy_hud.touch_rect("jump").get_center()
	e.pressed=false
	root.push_input(e,true)
	await ticks(8)
	check(game.player.position.y<580,"Touch jump uses real character physics")
	await ticks(15)
	e=InputEventScreenTouch.new()
	e.index=1
	e.position=game.whimsy_hud.touch_rect("jump").get_center()
	e.pressed=true
	root.push_input(e,true)
	await ticks(2)
	e=InputEventScreenTouch.new()
	e.index=1
	e.position=game.whimsy_hud.touch_rect("jump").get_center()
	e.pressed=false
	root.push_input(e,true)
	await ticks(3)
	check(game.player.jumps_used==2 and game.player.velocity.y<0,"Touch jump can be tapped again for the second jump")
	check(game.hint_button.text=="Bark's hint","Touch input removes unnecessary keyboard hint labels")
	await ticks(95)
	var start_x: float=game.player.position.x
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=game.whimsy_hud.touch_rect("right").get_center()
	e.pressed=true
	root.push_input(e,true)
	e=InputEventScreenTouch.new()
	e.index=1
	e.position=game.whimsy_hud.touch_rect("jump").get_center()
	e.pressed=true
	root.push_input(e,true)
	await ticks(15)
	check(game.player.position.x>start_x+25 and game.player.position.y<580,"Two fingers can move and jump together")
	for finger in [0,1]:
		e=InputEventScreenTouch.new()
		e.index=finger
		e.position=game.whimsy_hud.touch_rect("right").get_center() if finger==0 else game.whimsy_hud.touch_rect("jump").get_center()
		e.pressed=false
		root.push_input(e,true)
	await ticks(8)
	check(game.touch_fingers.is_empty() and not game.touches.right,"Both touch fingers release cleanly")
	await ticks(70)
	await press_key(KEY_SPACE)
	check(game.player.position.y<600 and not game.input_touch,"Keyboard jump still works after using touch controls")
	check("[H]" in game.hint_button.text,"Keyboard input restores its contextual hint shortcut")
	await ticks(70)
	Progress.settings.reduced_motion=true
	game.apply_settings()
	check(game.player.reduced_motion and game.campus.reduced_motion,"Reduced-motion setting reaches character and environment")
	check(not game.player.ghost.visible and game.player.sprite.modulate.a==1,"Reduced motion switches pose blending to a fully opaque sprite")
	game.show_settings(game.close_modal)
	var settings_buttons: Array[Button]=[]
	collect_buttons(game.modal,settings_buttons)
	var toggles=settings_buttons.filter(func(b):return b is CheckButton)
	check(toggles.size()==5 and toggles.all(func(b):return b.get_theme_color("font_color")==Color("203849") and ("On" in b.text or "Off" in b.text)),"Shared preferences use readable navy text and explicit On/Off labels")
	game.close_modal()
	check(game.player.air_rings.is_empty(),"Reduced-motion and completed jumps leave no moving jump effects")
	var stage=int(Progress.data.stage)
	game.player.position=Vector2(3720,605)
	game.sync_room()
	await walk_to(3635)
	check(game.campus.room==1,"Workshop exit returns to garden")
	check(int(Progress.data.stage)==stage and Progress.data.bark_token,"Room crossing preserves story and discoveries")
	await walk_to(1750)
	await walk_to(1630)
	check(game.campus.room==0,"Garden exit re-enters school")
	check(game.camera.position.x<=1060,"School camera excludes the garden")
	game.begin_room_transition(2,4240,"Test checkpoint")
	await ticks(25)
	check(game.campus.room==2 and game.room_transition.is_empty(),"Reduced-motion transition finishes without blocking input")
	game.restart_checkpoint()
	check(int(Progress.data.stage)==stage and Progress.data.bark_token,"Checkpoint restart preserves quest and discoveries")
	Progress.settings.music=false
	Progress.save_enabled=true
	Progress.save_game()
	Progress.reset_game(false)
	Progress.load_save()
	check(Progress.data.completed and Progress.data.bark_token and int(Progress.data.assembled)==3,"Disk save/load restores completed quest and inventory")
	check(not Progress.settings.music,"Music preference survives disk save/load")
	Progress.save_enabled=false
	var fallback=Art.tex("deliberately_missing_test_asset")
	check(fallback!=null,"Missing art has a safe fallback")
	check(not game.sounds.is_empty(),"Procedural sound cues load")
	# UI/QoL regressions use a temporary quest snapshot, then restore the adventure.
	var saved_quest=Progress.data.duplicate(true)
	var saved_settings=Progress.settings.duplicate(true)
	var saved_tutorial=Progress.tutorial_done
	var saved_position: Vector2=game.player.position
	Progress.data.stage=2
	Progress.data.plant=true
	game.update_hud()
	check("Return" in game.objective.text,"Carried plant objective gives the next action")
	Progress.data.stage=3
	Progress.data.books=true
	Progress.data.pencil=false
	game.update_hud()
	check("classroom" in game.objective.text and game.objective_icon.texture==Art.tex("collectibles_pencil"),"Last missing supply has a matching objective and pictogram")
	game.request_hint()
	check("Books secured!" in game.dialogue_text.text,"Hint adapts to the remaining supply")
	check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text.begins_with("Finish"),"Single-line dialogue focuses its Finish action")
	await dismiss()
	Progress.data.books=false
	Progress.data.pencil=true
	game.update_hud()
	check("garden" in game.objective.text,"Alternate supply order points back to the garden")
	await press_key(KEY_N)
	check(game.busy and root.gui_get_focus_owner().text=="Back to exploring","Notebook opens with a safe keyboard return action")
	await press_key(KEY_ESCAPE)
	check(not game.busy and game.player.enabled,"Escape closes the notebook into gameplay")
	game.show_pause()
	game.show_settings(game.show_pause)
	var volume_control: HSlider=null
	for child in game.modal.get_node("SharedSettings").get_children():
		if child is HSlider:volume_control=child
	volume_control.value=0.35
	check(game.modal.get_node("SharedSettings").get_children().any(func(c):return c is Label and c.text=="35%"),"Audio slider displays an exact percentage")
	await press_key(KEY_ESCAPE)
	check(game.busy and game.modal.get_children().any(func(c):return c is Label and c.text=="A LITTLE BREATHER"),"Escape from pause settings returns to pause")
	await press_key(KEY_ESCAPE)
	check(not game.busy,"A second Escape resumes gameplay")
	game.show_title()
	game.show_settings(game.show_title)
	await press_key(KEY_ESCAPE)
	check(game.mode=="title" and root.gui_get_focus_owner().text.begins_with("Continue"),"Escape from title settings restores the title and keyboard focus")
	game.confirm_new()
	check(root.gui_get_focus_owner().text=="Keep my adventure","New adventure confirmation defaults to preserving progress")
	await press_key(KEY_ESCAPE)
	check(Progress.data.stage==3 and game.mode=="title","Cancel new adventure preserves quest")
	game.start_campus()
	game.show_workshop()
	check(game.modal.get_children().filter(func(c):return c is Button and c.text.begins_with("✓ ")).size()==2,"Workshop marks both selected presets without relying on colour")
	var middle_button=game.modal.get_children().filter(func(c):return c is Button and "Middle 40°" in c.text)[0]
	middle_button.pressed.emit()
	check(root.gui_get_focus_owner().text=="✓ Middle 40°","Changing a preset retains keyboard focus on that selection")
	game.close_modal()
	game.flight={"kind":"workshop","t":0.0}
	game.show_notebook()
	check(not game.busy,"Notebook cannot interrupt a plane test")
	game.flight.clear()
	game.toast("A long helpful notice explains that you can jump again near the top of your first jump, land on the next platform, and try again safely whenever you need to.")
	check(game.toast_panel.size.y>=70 and game.toast_panel.size.y<=160 and game.toast_label.size.y<=game.toast_panel.size.y and game.toast_time>7,"Long notices fit their reading card and retain enough reading time")
	game.show_pause()
	var notice_time: float=game.toast_time
	await ticks(10)
	check(not game.toast_panel.visible and game.toast_time==notice_time,"Menus hide notices and preserve their reading time")
	game.close_modal()
	await ticks(2)
	check(game.toast_panel.visible,"Notice resumes after closing a menu")
	touches_cleanup_test()
	check(game.busy and game.touch_fingers.is_empty() and not game.touches.right and not Input.is_action_pressed("right"),"Losing window focus pauses exploration and releases movement")
	game.close_modal()
	# Malformed and duplicate save entries must not break UI or inflate counters.
	var corrupt=FileAccess.open(Progress.SAVE_PATH,FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"version":1,"data":{"leaves":["leaf_1","leaf_1","leaf_999",9],"discoveries":["doodle_1","doodle_1","unknown"],"attempts":-8},"settings":{"volume":{"invalid":true},"music":"false"},"tutorial_done":"false"}))
	corrupt.close()
	Progress.reset_game(false)
	Progress.settings.music=true
	Progress.load_save()
	check(Progress.data.leaves==["leaf_1"] and Progress.data.discoveries==["doodle_1"],"Save validation removes duplicate and unknown discoveries")
	check(Progress.settings.volume==0.45 and Progress.settings.music and not Progress.tutorial_done and Progress.data.attempts==0,"Malformed saved preferences and negative attempts recover safely")
	Progress.data=saved_quest
	Progress.settings=saved_settings
	Progress.tutorial_done=saved_tutorial
	game.player.position=saved_position
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	game.campus.refresh()
	game.apply_settings()
	# The replay tutorial must not erase the completed campus state.
	game.start_tutorial()
	await dismiss()
	game.finish_tutorial()
	check(Progress.data.completed and int(Progress.data.stage)==7,"Tutorial replay retains existing campus progress")
	if had_save:
		var file=FileAccess.open(Progress.SAVE_PATH,FileAccess.WRITE)
		file.store_string(original_save)
		file.close()
	else:DirAccess.remove_absolute(Progress.SAVE_PATH)
	var result={"passed":passed,"failures":failures,"godot_version":Engine.get_version_info().string,"notes":"Automated runtime playthrough uses keyboard events, real physics, GUI touch events and quest callbacks. It does not measure children's play duration."}
	DirAccess.make_dir_recursive_absolute("res://test_output")
	var report=FileAccess.open("res://test_output/playthrough.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(result,"\t"))
	report.close()
	print("RESULT: "+str(passed.size())+" passed; "+str(failures.size())+" failed")
	await game.soundscape.drain()
	game.queue_free()
	await ticks(5)
	get_tree().quit(0 if failures.is_empty() else 1)


func leap_to(x: float, top: float) -> void:
	var action="right" if x>game.player.position.x else "left"
	if absf(x-game.player.position.x)>12:Input.action_press(action)
	await press_key(KEY_SPACE)
	await ticks(23)
	await press_key(KEY_SPACE)
	var count=0
	while count<180:
		if absf(game.player.position.x-x)<15 or (action=="right" and game.player.position.x>x) or (action=="left" and game.player.position.x<x):
			Input.action_release(action)
		if game.player.is_on_floor() and absf(game.player.position.y-top)<3:break
		await ticks(1)
		count+=1
	Input.action_release(action)
	await ticks(5)
	check(count<180 and absf(game.player.position.y-top)<3,"Real double jump lands on route ledge at "+str(x)+", "+str(top))


func collect_buttons(parent: Node, result: Array[Button]) -> void:
	for child in parent.get_children():
		if child is Button:result.append(child)
		collect_buttons(child,result)


func collect_textures(parent: Node, result: Array[TextureRect]) -> void:
	for child in parent.get_children():
		if child is TextureRect:result.append(child)
		collect_textures(child,result)


func touches_cleanup_test() -> void:
	game.touch_fingers[0]="right"
	game.touches.right=true
	Input.action_press("right")
	game._notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
