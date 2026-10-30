extends Node
## Exercises actual scene controllers through Android's Back and suspend routes.
var passed=0
var failures=[]
var screenshots=false

func check(ok,message):
	if ok:passed+=1;print("PASS: "+message)
	else:failures.append(message);push_error("FAIL: "+message)

func ticks(n=4):
	for i in range(n):await get_tree().physics_frame
	await get_tree().process_frame

func capture(label):
	if not screenshots:return
	await RenderingServer.frame_post_draw
	var image=get_tree().root.get_texture().get_image()
	check(image!=null and not image.is_empty(),"Native phone presentation renders "+label)
	check(image.save_png("res://test_output/mobile_"+label+".png")==OK,"Native phone screenshot saves "+label)

func open_scene(path,action=""):
	Adventures.go(path,action)
	while Adventures.switching:await get_tree().process_frame
	await ticks(12)
	return get_tree().current_scene

func touch(game,index,action,pressed):
	var event=InputEventScreenTouch.new();event.index=index;event.pressed=pressed
	event.position=game.whimsy_hud.touch_rect(action).get_center()
	get_tree().root.push_input(event,true);await ticks()

func _ready():
	screenshots="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute("res://test_output")
	Progress.save_enabled=false;Mega.enabled=false
	Progress.settings.volume=0;Progress.settings.music=false;Progress.settings.touch=true
	call_deferred("run")

func run():
	# Keep this runner alive while the real current scene changes.
	get_tree().current_scene=null
	var home=await open_scene(Adventures.HOME)
	await capture("home")
	home.show_settings();await ticks();Adventures.back_mobile();await ticks()
	check(not is_instance_valid(home.settings_overlay),"Android Back closes home Settings")
	var game=await open_scene(Adventures.CLIMBS)
	game.load_level(0);await ticks(20);game.update_hud()
	await capture("library")
	check(game.touch_root.is_visible_in_tree(),"Climb controls appear on touch devices")
	var start=game.player.position.x
	await touch(game,1,"right",true);await ticks(20)
	await touch(game,2,"jump",true);await touch(game,2,"jump",false)
	check(game.player.position.x>start+10 and game.player.velocity.y<0,"Two fingers move and jump together")
	Adventures.suspend_mobile();await ticks()
	check(game.busy and game.fingers.is_empty() and game.player.axis==0,"Android suspend clears held climb input and pauses")
	var at=game.player.position;await ticks(15)
	check(game.player.position.distance_to(at)<1,"Suspended climb stays still until explicit Resume")
	Adventures.back_mobile();await ticks()
	check(not game.busy,"Android Back resumes the climb pause screen")
	game.pause_game();await ticks();game.settings(func():game.close();game.pause_game());await ticks();Adventures.back_mobile();await ticks()
	check(game.busy,"Android Back from climb Settings retains the pause screen")
	Adventures.back_mobile();await ticks()
	check(not game.busy,"Second Back resumes after leaving climb Settings")
	game.player.position=Vector2(765,647);game.player.velocity=Vector2.ZERO;await ticks(20)
	game.update_hud();await touch(game,4,"use",true);await touch(game,4,"use",false)
	check(game.campus.little_wonders.active==0,"Touch Use activates Pencil Patrol on the opening stage")
	Adventures.suspend_mobile();await ticks();var age=game.campus.little_wonders.age;await ticks(10)
	check(game.campus.little_wonders.age==age,"Backgrounding freezes the miniature encounter")
	var story=await open_scene(Adventures.STORY,"start_continue")
	# Complete the original shrinking introduction before testing live controls.
	if story.mode=="shrinking":story.shrinking_intro.finish();await ticks(20)
	if story.busy:story.close_modal();await ticks()
	story.update_hud();await ticks()
	story.touch_fingers[9]="right";story.touches.right=true
	Adventures.suspend_mobile();await ticks()
	check(story.touch_fingers.is_empty() and not story.touches.right and story.player.axis==0,"Android suspend clears held original-story input")
	check(story.busy,"Original story returns to a pause screen")
	Adventures.back_mobile();await ticks()
	check(not story.busy,"Android Back resumes the original story")
	var studio=await open_scene(Adventures.STUDIO)
	Adventures.suspend_mobile();await ticks();check(studio.paused,"Character studio pauses on Android suspend")
	Adventures.back_mobile()
	while Adventures.switching:await get_tree().process_frame
	await ticks();check(get_tree().current_scene.scene_file_path==Adventures.HOME,"Android Back returns from the studio to the adventure menu")
	await get_tree().current_scene.drain_audio()
	print("MOBILE RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
