extends Node
var game
var passed=0
var failures=[]
func check(ok,message):
	if ok:passed+=1;print("PASS: "+message)
	else:failures.append(message);push_error("FAIL: "+message)
func ticks(n=3):
	for i in range(n):await get_tree().physics_frame
func _ready():call_deferred("run")
func run():
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings=Progress.SETTING_DEFAULTS.duplicate(true)
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks()
	game.load_level(0);await ticks(5)
	check(game.campus.platforms.size()==27 and game.campus.pickups.size()==25,"All 24 main shelves, three nooks and 25 discoveries remain")
	check(game.campus.platforms[0]==Rect2(560,510,320,22) and game.campus.top==-3760,"Library entry collision and complete ascent are unchanged")
	check(game.campus.ledges.all(func(l):return l.library_style),"Only library platforms opt into the painted cast-shadow treatment")
	check(game.campus.get_children().filter(func(n):return n.name.begins_with("LibraryContactShadow")).size()==2,"Both painted friends have independent world contact shadows")
	check(game.player.sprite.character3d.active and game.campus.bark.character3d.active and game.player.sprite.texture==Art.tex("young_actions_idle"),"Default library actors use genuine3D while retaining their original pose artwork")
	check(not game.library_header.is_visible_in_tree() and not game.objective.is_visible_in_tree() and not game.counters.is_visible_in_tree(),"Quest detail stays available as data without the old full-width header")
	check(not game.route_label.is_visible_in_tree(),"Keyboard ascent keeps shelf detail out of the always-on view")
	Progress.settings.touch=true;game.update_hud();await ticks()
	check(game.touch_root.visible and not game.route_label.is_visible_in_tree(),"Touch mode keeps necessary controls without restoring the shelf panel")
	game.library_pulses.clear();game.library_pulse(Vector2(500,500),"spring");check(game.library_pulses.size()==1,"Bark spring can trigger a restrained visual ring")
	game.pause_game();var age=game.library_pulses[0].age;await ticks(10)
	check(game.library_pulses[0].age==age,"Pause freezes library feedback")
	game.close();Progress.settings.reduced_motion=true;game.library_pulses.clear();game.library_pulse(Vector2.ZERO,"landing")
	check(game.library_pulses.is_empty(),"Reduced motion suppresses the new feedback")
	game.load_level(1);await ticks()
	check(not game.library_header.is_visible_in_tree() and not game.campus.ledges[0].library_style and game.library_pulses.is_empty(),"Bedroom keeps the minimal HUD and its own platform presentation")
	game.load_level(2);await ticks();check(game.campus.RISES[2].size()==33,"Attic keeps every original shelf")
	game.load_level(0);await ticks()
	if "--screenshots" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://test_output")
		Progress.settings.touch=false
		for shelf in [0,8,16,23]:
			var r=game.campus.platforms[shelf];game.place_player(Vector2(r.get_center().x,r.position.y-3));await ticks(40);game.last_shelf=shelf+1;Mega.runs[0].checkpoint=maxi(0,shelf-1);game.update_hud();await ticks(2)
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("res://test_output/library_shelf_"+str(shelf+1)+".png")
	check(Art.missing_assets.is_empty(),"Every requested painted library asset resolves")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain()
	print("LIBRARY RESULT: ",passed," passed; ",failures.size()," failed");get_tree().quit(0 if failures.is_empty() else 1)
