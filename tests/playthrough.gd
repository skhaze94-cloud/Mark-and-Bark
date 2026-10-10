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
	check(Art.tex("workshop_hub_v2").get_width()>1200,"Detailed workshop backdrop is bundled")
	check(Art.tex("school_door_v2").get_image().detect_alpha()!=Image.ALPHA_NONE,"Doorway sprite has genuine transparency")
	check(game.campus.depth!=null and game.campus.foreground.z_index>game.player.z_index,"Depth scenery and foreground layers are separate")
	await capture("01_title")
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
	await press_key(KEY_E)
	await dismiss()
	check(game.tutorial_step==3,"Keyboard interacts with notebook")
	await walk_to(855)
	check(game.tutorial_step==4,"Tutorial leaf auto-collects")
	await press_key(KEY_H)
	await dismiss()
	check(game.tutorial_step==5,"Hint advances tutorial")
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
	await walk_to(810)
	await press_key(KEY_E)
	await dismiss()
	check(int(Progress.data.stage)==1,"Fair invitation starts quest")
	await capture("02_hallway")
	await walk_to(1910)
	check(game.campus.room==1 and game.transitions_completed>=1,"Walking off hallway enters a separate garden room")
	check(game.camera.position.x>=2340,"Garden camera excludes the hallway")
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
	# Books are reachable with a real jump from the ground, not a teleport.
	await press_key(KEY_SPACE)
	await ticks(13)
	await press_key(KEY_E)
	await ticks(40)
	check(Progress.data.books,"Required elevated book stack is reachable")
	await walk_to(3500)
	await press_key(KEY_E)
	check(Progress.data.pencil and int(Progress.data.stage)==4,"Pencil collection completes supply list")
	await walk_to(3630)
	await press_key(KEY_E)
	await ticks(65)
	check(game.campus.room==2 and game.player.position.x>4200,"Unlocked garden shortcut reaches workshop")
	await walk_to(4430)
	await press_key(KEY_E)
	check(int(Progress.data.stage)==5 and game.busy,"Workshop opens after supplies")
	game.assemble_next()
	game.assemble_next()
	game.assemble_next()
	await ticks(3)
	check(int(Progress.data.assembled)==3 and int(Progress.data.stage)==6,"All assembly steps persist")
	await capture("04_workshop")
	game.angle_choice=0
	game.power_choice=0
	game.launch_workshop()
	await ticks(220)
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
	await dismiss()
	check(game.busy,"Ending summary opens")
	await capture("05_ending")
	game.close_modal()
	check(game.player.enabled,"Post-ending exploration remains available")
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
	e.position=Vector2(175,650)
	e.pressed=true
	root.push_input(e,true)
	await ticks(20)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=Vector2(175,650)
	e.pressed=false
	root.push_input(e,true)
	await ticks(6)
	check(game.player.position.x>before+15,"Screen touch holds right movement and releases")
	check(not game.touches.right,"Touch release clears movement")
	# Exercise touch Jump via its actual GUI signal path.
	await ticks(30)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=Vector2(315,650)
	e.pressed=true
	root.push_input(e,true)
	await ticks(2)
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=Vector2(315,650)
	e.pressed=false
	root.push_input(e,true)
	await ticks(8)
	check(game.player.position.y<580,"Touch jump uses real character physics")
	await ticks(70)
	var start_x: float=game.player.position.x
	e=InputEventScreenTouch.new()
	e.index=0
	e.position=Vector2(175,650)
	e.pressed=true
	root.push_input(e,true)
	e=InputEventScreenTouch.new()
	e.index=1
	e.position=Vector2(315,650)
	e.pressed=true
	root.push_input(e,true)
	await ticks(15)
	check(game.player.position.x>start_x+25 and game.player.position.y<580,"Two fingers can move and jump together")
	for finger in [0,1]:
		e=InputEventScreenTouch.new()
		e.index=finger
		e.position=Vector2(175,650) if finger==0 else Vector2(315,650)
		e.pressed=false
		root.push_input(e,true)
	await ticks(8)
	check(game.touch_fingers.is_empty() and not game.touches.right,"Both touch fingers release cleanly")
	await ticks(70)
	Progress.settings.reduced_motion=true
	game.apply_settings()
	check(game.player.reduced_motion and game.campus.reduced_motion,"Reduced-motion setting reaches character and environment")
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
	Progress.save_enabled=true
	Progress.save_game()
	Progress.reset_game(false)
	Progress.load_save()
	check(Progress.data.completed and Progress.data.bark_token and int(Progress.data.assembled)==3,"Disk save/load restores completed quest and inventory")
	Progress.save_enabled=false
	var fallback=Art.tex("deliberately_missing_test_asset")
	check(fallback!=null,"Missing art has a safe fallback")
	check(not game.sounds.is_empty(),"Procedural sound cues load")
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
	get_tree().quit(0 if failures.is_empty() else 1)
