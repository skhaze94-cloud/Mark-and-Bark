extends Node
var game
var passed=0
var failures=[]
var screenshots=false
func check(ok,name):
	if ok:passed+=1;print("PASS: "+name)
	else:failures.append(name);push_error("FAIL: "+name)
func ticks(n=2):
	for i in range(n):await get_tree().physics_frame
func key(code):
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);await ticks(2)
	e=InputEventKey.new();e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);await ticks(2)
func capture(name):
	if not screenshots:return
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/"+name+".png")
func climb(r,name):
	var x=r.get_center().x
	game.jump()
	var landed=false
	for t in range(150):
		var dx=x-game.player.position.x
		Input.action_release("left");Input.action_release("right")
		if absf(dx)>7:Input.action_press("right" if dx>0 else "left")
		if t==24:game.jump()
		await ticks(1)
		if t>28 and game.player.is_on_floor() and absf(game.player.position.y-r.position.y)<6:
			landed=true;break
	Input.action_release("left");Input.action_release("right");await ticks(8)
	check(landed,name+" reachable with actual double-jump physics")
	return landed
func _ready():call_deferred("run")
func run():
	await ticks()
	get_tree().root.size=Vector2i(1280,720)
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=false
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://test_output")
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(5)
	check(game.mode=="title" and game.busy,"Title loads");await capture("mega_title")
	game.start();await ticks(2)
	check(game.mode=="ray" and game.player.visual_scale>.4,"Animated shrinking ray opens the adventure")
	game.intro_ray.age=4;game.intro_ray.update_story();await capture("mega_shrinking_ray")
	await key(KEY_E);await ticks(2)
	check(game.busy and game.dialogue.size()==5,"Shrinking story introduces the quest and teamwork")
	await capture("mega_opening");await key(KEY_E);check(game.page==1,"Keyboard advances story")
	game.end_dialogue();await ticks(8);check(Mega.intro_done and not game.busy,"Skipping intro unlocks movement")
	await capture("mega_school_floor")
	await key(KEY_N);check(game.busy,"Notebook opens");await key(KEY_ESCAPE);check(not game.busy,"Escape closes notebook")
	await key(KEY_H);check(game.busy and String(game.dialogue[0]).contains("apex"),"Bark gives actionable climbing hints");game.end_dialogue()
	await key(KEY_ESCAPE);var frozen=game.player.position;await ticks(20);check(game.player.position==frozen,"Pause freezes player physics");await key(KEY_ESCAPE)
	for level in range(3):
		if level>0:game.load_level(level)
		await ticks(8);await capture("mega_level_"+str(level+1)+"_floor")
		check(game.campus.platforms.size()==[27,30,36][level],"Level "+str(level+1)+" has its own climb and secret shelf")
		for n in range(game.campus.RISES[level].size()):
			if not await climb(game.campus.platforms[n],"Level "+str(level+1)+" shelf "+str(n+1)):break
			if n%2==1:check(Mega.runs[level].checkpoint==n,"Checkpoint saved at shelf "+str(n+1))
			if n in game.campus.branch_indices:
				await capture("mega_level_"+str(level+1)+"_middle")
				await climb(game.campus.platforms[game.campus.RISES[level].size()+game.campus.branch_indices.find(n)],"Level "+str(level+1)+" discovery branch")
				check(Mega.runs[level].token,"Secret Bark token collected by platforming")
				await climb(game.campus.platforms[n],"Return from secret branch")
			if n==game.campus.RISES[level].size()-2:
				await key(KEY_E);check(Mega.runs[level].quest,"Quest item recovered using keyboard interaction")
				if game.busy:game.end_dialogue()
		await capture("mega_level_"+str(level+1)+"_top")
		check(Mega.runs[level].leaves.size()==24,"All 24 leaves collected on level "+str(level+1))
		check(game.spring_contacts>=5,"Bark-assisted spring is central to climbing")
		await key(KEY_E)
		if level==2:
			check(game.mode=="ray" and game.intro_ray.restoring,"Final delivery triggers the restored-size cinematic")
			game.intro_ray.age=6;game.intro_ray.update_story();check(game.player.visual_scale>.4,"Repaired ray visibly grows Mark again");await capture("mega_restored_ray");await key(KEY_E)
		check(Mega.best[level].complete and game.busy,"Delivery completes level "+str(level+1))
		check(Mega.unlocked==mini(3,level+2),"Next level unlock is persistent")
		await capture("mega_level_"+str(level+1)+"_ending")
		game.close();check(game.player.enabled,"Exploration remains available after ending")
		var saved=JSON.stringify(Mega.runs[level]);await key(KEY_R);check(JSON.stringify(Mega.runs[level])==saved,"Checkpoint retry preserves discoveries");await ticks(8)
		check(game.player.is_on_floor() and absf(game.player.position.y-game.campus.platforms[Mega.runs[level].checkpoint].position.y)<5,"Checkpoint retry settles safely on the saved platform")
	game.load_level(0);await ticks(8)
	var touch=InputEventScreenTouch.new();touch.index=3;touch.position=Vector2(150,650);touch.pressed=true;get_tree().root.push_input(touch,true);await ticks(8)
	check(game.player.velocity.x>150 and game.touch_root.visible,"Touch hold moves Mark and switches prompts")
	touch=InputEventScreenTouch.new();touch.index=4;touch.position=Vector2(880,650);touch.pressed=true;get_tree().root.push_input(touch,true);await ticks(8)
	check(not game.player.is_on_floor(),"Touch jump works while another finger holds movement")
	touch=InputEventScreenTouch.new();touch.index=4;touch.pressed=false;get_tree().root.push_input(touch,true);await ticks(18)
	touch=InputEventScreenTouch.new();touch.index=5;touch.position=Vector2(880,650);touch.pressed=true;get_tree().root.push_input(touch,true);await ticks(2)
	check(game.player.jumps_used==2 and game.spring_age<.1,"Touch second jump starts Mark-on-Bark contact animation")
	await capture("mega_spring_contact")
	await ticks(9);await capture("mega_spring_release")
	game.fingers.clear();await ticks(90)
	game.retry();await ticks(8);Progress.settings.reduced_motion=true;game.jump();await ticks(26);game.jump();await ticks(2)
	check(game.campus.bark.scale==Vector2.ONE*.2,"Reduced motion preserves a clear stable teamwork pose")
	game.jump();await ticks(2);check(game.player.jumps_used==2,"A third airborne jump cannot be exploited")
	check(game.player.sprite.offset==Vector2(-256,-612),"Original Mark foot pivot remains exact")
	check(game.campus.bark.offset==Vector2(-256,-612),"Bark contact uses original foot pivot")
	# Save and reload real campaign progress without overwriting the player's save.
	var existed=FileAccess.file_exists(Mega.PATH);var previous=FileAccess.get_file_as_string(Mega.PATH) if existed else ""
	Mega.enabled=true;Mega.save();var state=JSON.stringify(Mega.runs);Mega._ready();check(JSON.stringify(Mega.runs)==state and Mega.best[2].complete,"Campaign, quest items and best scores survive save/reload")
	if existed:
		var f=FileAccess.open(Mega.PATH,FileAccess.WRITE);f.store_string(previous);f.close()
	else:DirAccess.remove_absolute(Mega.PATH)
	Mega.enabled=false
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4)
	print("MEGA RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
