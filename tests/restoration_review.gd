extends Node

var passed=0
var failures=[]
var screenshots=false

func check(ok,description):
	if ok:passed+=1;print("PASS: "+description)
	else:failures.append(description);push_error("FAIL: "+description)

func ticks(n=3):
	for i in range(n):await get_tree().physics_frame

func capture(label):
	if not screenshots:return
	await ticks(3);await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/restoration_"+label+".png")

func controls_fit(node):
	var valid=true
	for child in node.get_children():
		if child is Control:
			var inside=Rect2(0,0,1280,720).grow(1).encloses(child.get_global_rect());valid=valid and inside
			if not inside:print("Outside viewport: ",child.name," ",child.get_global_rect())
		valid=valid and controls_fit(child)
	return valid

func menu_button(node,value):
	for child in node.get_children():
		if child is Button and child.text==value:return child
	return null

func wait_for_scene(path):
	var deadline=Time.get_ticks_msec()+8000
	while Time.get_ticks_msec()<deadline:
		var scene=get_tree().current_scene
		if not Adventures.switching and is_instance_valid(scene) and scene.scene_file_path==path:return scene
		await get_tree().process_frame
	check(false,"Navigation completes: "+path)
	return null

func _ready():call_deferred("run")

func run():
	# Keep this controller outside current_scene so real scene changes are tested.
	get_tree().current_scene=null
	await ticks();get_tree().root.size=Vector2i(1280,720)
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://test_output")
	Progress.save_enabled=false;Mega.enabled=false;Progress.reset_game(false);Mega.reset(false)
	Progress.settings.painted_characters=true;Progress.settings.reduced_motion=false
	check(ProjectSettings.get_setting("application/run/main_scene")==Adventures.HOME,"F5 opens the complete adventure menu")
	var all_present=true
	for id in Art.index:
		all_present=all_present and ResourceLoader.exists(Art.index[id].path)
		var texture=Art.tex(id);all_present=all_present and texture!=null and texture.get_width()>64
	check(all_present and Art.missing_assets.is_empty(),"Every registered artwork asset resolves without a placeholder")
	var actor=Art.game_actor("young_actions_idle");add_child(actor);await ticks()
	for id in actor.profiles:
		actor.texture=Art.tex(id);actor.drive("jump",false,Vector2(120,-300));await ticks(1)
		check(actor.self_modulate.a==1 and not actor.mesh.visible and actor.texture==Art.tex(id),"Original painting stays intact: "+id)
	Progress.settings.painted_characters=false;actor.texture=Art.tex("young_actions_idle");await ticks()
	check(actor.mesh.visible and actor.self_modulate.a==0,"Extra articulation can be enabled without replacing the source art")
	var image=Image.create(8,8,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE);actor.texture=ImageTexture.create_from_image(image);await ticks()
	check(actor.profile.is_empty() and not actor.mesh.visible and actor.self_modulate.a==1,"Uncalibrated artwork cannot inherit a previous character's mesh or face")
	actor.queue_free();await ticks()
	check(Art.tex("young_actions_missing_review")==Art.tex("young_actions_idle"),"Missing Mark pose falls back to Mark rather than a gold square")
	check(Art.missing_assets==["young_actions_missing_review"],"Missing artwork is recorded for diagnosis")
	Art.missing_assets.clear()
	Progress.settings.painted_characters=true
	await Adventures.go(Adventures.HOME);var home=get_tree().current_scene;await ticks(8)
	check(controls_fit(home),"Adventure menu text and controls stay inside the viewport")
	check(home.mark.texture==Art.tex("young_actions_notebook") and home.bark.texture==Art.tex("bark_actions_cheer"),"Menu stages the supplied character identities prominently")
	check(not home.mark.mesh.visible and not home.bark.mesh.visible,"Original painted character presentation is the default")
	home.paint_toggle.button_pressed=false;await ticks(2)
	check(not Progress.settings.painted_characters and home.mark.mesh.visible and home.bark.mesh.visible,"The appearance control updates both friends immediately")
	home.paint_toggle.button_pressed=true
	await capture("adventures")
	Progress.data.stage=3;Progress.data.notebook=true;Mega.runs[0].leaves=[1,2];Mega.runs[0].checkpoint=3
	var story_before=Progress.data.duplicate(true);var climb_before=Mega.runs.duplicate(true)
	home.story_button.pressed.emit();var story=await wait_for_scene(Adventures.STORY);await ticks(5)
	check(story.mode=="shrinking" and story.shrinking_intro.running,"The story card really enters the original shrinking intro")
	story.shrinking_intro.finish();story.dismiss_dialogue();story.show_title();await ticks()
	check(menu_button(story.modal,"All adventures")!=null and menu_button(story.modal,"Watch the campus film")!=null,"Original title exposes the film and a return to all adventures")
	story.start_campus();story.dismiss_dialogue();story.player.position=Vector2(2740,249);story.player.velocity=Vector2.ZERO;story.sync_room();await ticks(6)
	check(story.campus.backgrounds.size()==3 and story.campus.board!=null and story.campus.fun_ledges.size()>0,"Original rooms, interactive invention board and elevated routes remain playable")
	for kind in ["book","pencil","leaf"]:
		var ledges=story.campus.fun_ledges.filter(func(ledge):return ledge.kind==kind)
		var painted=not ledges.is_empty() and ledges.all(func(ledge):return ledge.atlas!=null and ledge.region.size.x>0)
		check(painted,"Original chapter uses actual painted platform artwork: "+kind)
	await capture("garden")
	Progress.settings.painted_characters=false;story.show_pause();await ticks(4)
	var mark_age=story.player.sprite.age;var bark_age=story.campus.bark.age;var bark_position=story.campus.bark.position
	await ticks(20)
	check(story.player.sprite.age==mark_age and story.campus.bark.age==bark_age and story.campus.bark.position==bark_position,"Original chapter pause freezes both actors and the companion position")
	story.close_modal();await ticks(5)
	check(story.campus.bark.age>bark_age,"Original chapter resumes the companion animation after pause")
	story.player.position=Vector2(4490,605);story.sync_room();await ticks(8);await capture("workshop")
	Progress.settings.painted_characters=true
	story.show_title();menu_button(story.modal,"All adventures").pressed.emit();home=await wait_for_scene(Adventures.HOME)
	check(Mega.runs==climb_before,"Visiting the original adventure preserves the climbing save")
	var retained_story=Progress.data.duplicate(true)
	home.climb_button.pressed.emit();var climbs=await wait_for_scene(Adventures.CLIMBS);await ticks(4)
	check(climbs.mode=="ray" and climbs.intro_ray.running,"The climbing card really enters the separate campaign")
	climbs.intro_ray.finish();climbs.end_dialogue();climbs.title();await ticks()
	check(menu_button(climbs.panel,"All adventures")!=null,"Climbing title has a visible route back to the story")
	check(Progress.data==retained_story,"Entering the climbs preserves story progress")
	for i in range(3):
		climbs.load_level(i);await ticks(6)
		check(climbs.campus.RISES[i].size()==[24,27,33][i] and climbs.campus.pickups.size()==25,"Complete climbing route and discoveries remain available: "+str(i+1))
	await Adventures.go(Adventures.STUDIO);var studio=get_tree().current_scene;await ticks(4)
	check(studio.mark.mesh.visible and studio.bark.mesh.visible,"Character studio retains the full articulated renderer")
	var escape=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true;get_tree().root.push_input(escape,true)
	home=await wait_for_scene(Adventures.HOME);await ticks(3)
	check(home!=null,"Studio Escape returns to all adventures")
	check(Art.missing_assets.is_empty(),"Story, climbs and studio do not request missing art")
	await capture("return_home")
	await home.drain_audio()
	print("RESTORATION RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
