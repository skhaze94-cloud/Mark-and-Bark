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
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=true;get_tree().root.push_input(e,true);await ticks(2)
	e=InputEventKey.new();e.physical_keycode=code;e.pressed=false;get_tree().root.push_input(e,true);await ticks(2)
func capture(name):
	if not screenshots:return
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/polish_"+name+".png")
func inspect_controls(node,panel_bounds):
	for c in node.get_children():
		if c is Control:
			var r=c.get_global_rect()
			check(panel_bounds.grow(2).encloses(r),"Menu control fits: "+c.get_class())
		inspect_controls(c,panel_bounds)
func _ready():call_deferred("run")
func run():
	await ticks();get_tree().root.size=Vector2i(1280,720);screenshots="--screenshots" in OS.get_cmdline_user_args()
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=false
	DirAccess.make_dir_recursive_absolute("res://test_output")
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(5)
	check(is_equal_approx(game.player.visual_scale,.42) and is_equal_approx(game.campus.bark.scale.x,.35),"Title stages both friends clearly")
	await capture("title")
	game.level_select();await ticks(3);inspect_controls(game.panel,game.panel.get_global_rect());await capture("level_select")
	await key(KEY_ESCAPE);check(game.mode=="title","Escape returns from level selection")
	game.say(["Bark|We are reviewing every little detail, including portraits that fit inside their paper panels."]);await ticks(3);inspect_controls(game.panel,game.panel.get_global_rect());await capture("dialogue");game.end_dialogue()
	game.how_to_play(game.title);await ticks(3);inspect_controls(game.panel,game.panel.get_global_rect());await capture("how_to_play");await key(KEY_ESCAPE)
	game.load_level(0);await ticks(8)
	check(game.player.visual_scale==.24,"Starting gameplay restores the correct miniature size")
	check(game.objective_icon.texture==Art.tex(game.campus.ASSETS[0]),"HUD depicts the current quest item")
	check(game.last_shelf==0 and game.route_label.text.contains("Shelf 0 / 8"),"HUD identifies the starting floor")
	check(game.height_meter.get_global_rect().end.y<=game.height_meter.get_parent().get_global_rect().end.y,"Thin progress meter fits inside the header")
	check(Art.tex("mega_power_cell").get_width()==256 and Art.tex("mega_ray_lens").get_width()==256,"Quest supplies use properly imported cell and lens icons")
	check(game.height_meter.value>=0 and game.height_meter.value<=100,"Climb progress remains bounded")
	game.toast("Bark has a particularly long explanation about jumping, learning, exploring and returning to a checkpoint. Mark would like some time to read every word before it disappears. Thank you, Bark.")
	await ticks(2);check(game.notice_back.visible and game.notice_back.size.y==96,"Long notices have a readable backing and extra room")
	var remaining=game.notice_until-game.clock;game.pause_game();await ticks(30)
	check(not game.notice_back.visible,"Notices hide while a menu is open")
	check(absf((game.notice_until-game.clock)-remaining)<.03,"Pause preserves remaining notice reading time")
	await capture("pause");game.settings(func():game.close());await ticks(2);inspect_controls(game.panel,game.panel.get_global_rect());await capture("settings");game.close()
	Mega.runs[0].checkpoint=1;game.campus.refresh();check(game.campus.checkpoints[0].sprite.texture==Art.tex("ui_parts_reward_check"),"Saved checkpoint bulb becomes a completion check")
	game.retry();await ticks(8);check(game.last_shelf==2,"Retry restores the shelf counter")
	game.jump();await ticks(26);game.jump();await ticks(3)
	check(game.player.spring_contact and not game.player.ghost.visible and game.player.sprite.modulate.a==1,"Contact pose stays crisp without a second ghost Mark")
	await capture("contact");await ticks(12);await capture("release")
	game.retry();await ticks(8)
	var secret=game.campus.platforms[-1];game.player.position=Vector2(secret.get_center().x,secret.position.y-1);game.player.velocity=Vector2.ZERO;await ticks(8);game.hint()
	check(String(game.dialogue[0]).contains("Return to shelf 5"),"Secret-shelf hint directs players back to the reachable route");game.end_dialogue()
	Mega.best[0].complete=true;Mega.best[0].leaves=3;Mega.runs[0].leaves=[0,1,2,3,4,5];Mega.runs[0].token=true;Mega.save()
	check(Mega.best[0].leaves==6 and Mega.best[0].token,"Extra discoveries update best scores immediately after completion")
	game.level_select();await key(KEY_ESCAPE);check(game.mode=="campus" and game.player.enabled,"Level-select Back returns to the active climb")
	game.result();await ticks(2);await capture("ending");await key(KEY_ESCAPE);check(game.player.enabled and not game.result_open,"Escape from ending returns to exploration")
	game.next_level(1);await ticks(2);check(game.travelling and game.busy and game.player.suspended,"Level transition locks movement safely")
	await key(KEY_ESCAPE);check(game.travelling,"Escape cannot interrupt the middle of a transition")
	await ticks(40);check(Mega.current==1 and not game.travelling and game.player.enabled and not game.travel_veil.visible,"Transition finishes in the next playable level")
	check(game.ambient.color==Color("f1f7ed"),"Bedroom has its own gentle lighting grade");await capture("bedroom")
	Progress.settings.reduced_motion=true;game.next_level(2);await ticks(2);check(Mega.current==2 and not game.travelling,"Reduced motion switches levels without animated fade")
	check(not game.campus.scenery.motes.visible,"Reduced motion disables decorative dust");await capture("attic")
	game.retry();await ticks(8);Progress.settings.touch=true;game.update_hud()
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=Vector2(150,650);e.pressed=true;get_tree().root.push_input(e,true);await ticks(8)
	check(game.player.velocity.x>150,"Mouse can hold the displayed movement arrows")
	e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=Vector2(150,650);e.pressed=false;get_tree().root.push_input(e,true);await ticks(3);check(not game.fingers.has(-2),"Mouse release clears the held arrow")
	Progress.settings.volume=0;game._physics_process(0);check(game.effects.volume_db<-70,"Master mute also silences an active feedback sound")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4)
	print("POLISH RESULT: ",passed," passed; ",failures.size()," failed");get_tree().quit(0 if failures.is_empty() else 1)
