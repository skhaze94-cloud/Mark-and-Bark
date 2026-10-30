extends Node
var passed = 0
var failures: Array = []
var game
var screenshots = false

func check(ok, message):
	if ok: passed+=1;print("PASS: "+message)
	else: failures.append(message);push_error("FAIL: "+message)

func ticks(n=4):
	for i in range(n): await get_tree().physics_frame
	await get_tree().process_frame

func _ready():
	Progress.save_enabled=false;Mega.enabled=false
	screenshots="--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("run")

func capture(label):
	if not screenshots: return
	await ticks(3);await RenderingServer.frame_post_draw
	var image=get_tree().root.get_texture().get_image()
	check(image!=null and not image.is_empty(),"Native wonder renders "+label)
	check(image.save_png("res://test_output/wonders_"+label+".png")==OK,"Wonder screenshot saves "+label)

func stand(at):
	game.close();game.player.set_physics_process(true)
	game.player.position=at+Vector2(85,-3);game.player.velocity=Vector2.ZERO
	game.spring_age=9;game.campus.bark.position=at+Vector2(140,0)
	await ticks(24)
	game.set_physics_process(false);game.player.set_physics_process(false)
	game.player.sprite.frozen=true;game.campus.bark.frozen=true
	game.camera.position=at+Vector2(35,-112);game.camera.zoom=Vector2.ONE*1.65;game.camera.force_update_scroll()
	game.notice_until=0;game.tutorial_hint_until=0;game.update_hud()
	await ticks()

func run():
	DirAccess.make_dir_recursive_absolute("res://test_output")
	Mega.reset(false);Progress.settings=Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.music=false;Progress.settings.volume=0;Mega.prefs.calm=true
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks()
	game.load_level(0);await ticks()
	var director=game.campus.little_wonders
	check(is_instance_valid(director) and director.entries.size()==3,"Exactly three miniature lives belong to the first climb")
	check(game.campus.platforms.size()==27 and game.campus.pickups.size()==25,"Wonders keep every original shelf and collectible")
	var original=game.campus.platforms.duplicate()
	var story=Progress.data.duplicate(true)
	var before=Mega.runs[0].duplicate(true)
	game.player.position=Vector2(510,647);await ticks()
	check(not director.can_interact(),"Starting movement and tutorial remain clear of the encounter input")
	for id in range(3):
		var entry=director.entries[id]
		await stand(entry.at)
		check(director.nearest()==id and director.can_interact(),"Encounter "+str(id)+" is reachable from its real supporting surface")
		check(absf(game.campus.bark.position.x-entry.at.x)>95,"Bark leaves encounter "+str(id)+" visibly clear beside Mark")
		Progress.settings.touch=true;game.update_hud();await ticks()
		check(game.touch_use.is_visible_in_tree(),"Encounter "+str(id)+" exposes the existing touch Use control")
		Progress.settings.touch=false
		director.set_process(false);director.age=0;director.queue_redraw()
		await capture(str(id)+"_waiting")
		if id==1:
			Progress.settings.touch=true;game.update_hud()
			var touch=InputEventScreenTouch.new();touch.index=7;touch.position=game.whimsy_hud.touch_rect("use").get_center();touch.pressed=true
			get_tree().root.push_input(touch,true);await ticks()
			touch=InputEventScreenTouch.new();touch.index=7;touch.pressed=false;get_tree().root.push_input(touch,true)
			Progress.settings.touch=false
			check(director.active==1,"Actual touch Use input reaches Snail Mail")
		else: game.interact()
		check(director.active==id and not game.busy,"Encounter "+str(id)+" starts without a modal or movement lock")
		check(not director.interact(),"Encounter "+str(id)+" rejects rapid duplicate input")
		director.age=2.8;director.queue_redraw()
		await capture(str(id)+"_reveal")
		director.set_process(true);game.pause_game();await ticks()
		var age=director.age;var clock=director.time
		await ticks(12)
		check(director.age==age and director.time==clock,"Pause freezes encounter "+str(id)+" completely")
		game.close();director.age=5.99;await ticks()
		check(id in Mega.runs[0].wonders and director.active==-1,"Encounter "+str(id)+" records its discovery after the reveal")
		director.set_process(false);director.cooldown=0;director.queue_redraw()
		await capture(str(id)+"_aftermath")
		var visits=Mega.runs[0].wonders.duplicate()
		Progress.settings.reduced_motion=true
		check(director.interact() and director.active==-1 and Mega.runs[0].wonders==visits,"Reduced-motion repeat "+str(id)+" resolves immediately without duplicate rewards")
		Progress.settings.reduced_motion=false;director.cooldown=0;director.set_process(true)
	check(Mega.runs[0].wonders.size()==3 and director.notebook_text().contains("3 / 3"),"All three optional discoveries appear in the Notebook")
	check(Mega.runs[0].checkpoint==before.checkpoint and Mega.runs[0].leaves==before.leaves and Mega.runs[0].quest==before.quest and Mega.runs[0].token==before.token,"Tiny lives do not grant leaves, skip checkpoints or change the quest")
	check(Progress.data==story and game.campus.platforms==original,"The complete story and first-stage collision route are preserved")
	# Real keyboard routing, rather than only calling the encounter directly.
	await stand(director.entries[0].at);director.cooldown=0
	var key=InputEventKey.new();key.physical_keycode=KEY_E;key.pressed=true
	get_tree().root.push_input(key,true);await ticks()
	check(director.active==0,"Actual E input reaches a nearby miniature encounter")
	director.age=5.99;await ticks()
	var saved_path=Mega.save_path;var old_store=Mega.storage
	var saved_runs=Mega.runs.duplicate(true);var saved_best=Mega.best.duplicate(true)
	var saved_current=Mega.current;var saved_unlocked=Mega.unlocked;var saved_intro=Mega.intro_done
	var folder="user://wonders_review_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder);Mega.save_path=folder+"/save.json"
	Mega.storage=load("res://scripts/save_storage.gd").new();Mega.enabled=true
	check(Mega.save(),"Wonder discoveries save through the existing atomic store")
	Mega._ready()
	check(Mega.runs[0].wonders.size()==3,"A cold reload restores all three miniature lives")
	Mega.save();Mega.storage.write_text(Mega.save_path,"{interrupted");Mega._ready()
	check(Mega.recovered_backup and Mega.runs[0].wonders.size()==3,"Validated backup recovers the optional discoveries after an interrupted write")
	Mega.storage.write_text(Mega.save_path,JSON.stringify({"version":2,"runs":[{"checkpoint":4,"leaves":[1,8],"wonders":[0,0,1,2,2.5,-1,99,"1",true]}]}))
	Mega._ready()
	check(Mega.runs[0].wonders==[0,1,2] and Mega.runs[0].leaves==[1,8] and Mega.runs[0].checkpoint==4,"Malformed wonder values are rejected without losing valid campaign data")
	Mega.storage.write_text(Mega.save_path,JSON.stringify({"version":1,"runs":[{"checkpoint":2,"leaves":[3]}]}));Mega._ready()
	check(Mega.runs[0].wonders.is_empty() and Mega.runs[0].checkpoint==2 and Mega.runs[0].leaves==[3],"Older saves gain empty optional discoveries and retain their progress")
	Mega.enabled=false;Mega.save_path=saved_path;Mega.storage=old_store;Mega.runs=saved_runs;Mega.best=saved_best;Mega.current=saved_current;Mega.unlocked=saved_unlocked;Mega.intro_done=saved_intro
	game.camera.zoom=Vector2.ONE
	for level in [1,2]:
		game.load_level(level);await ticks()
		check(not is_instance_valid(game.campus.little_wonders),"Climb "+str(level+1)+" receives no first-stage encounter layer")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain()
	print("WONDERS RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
