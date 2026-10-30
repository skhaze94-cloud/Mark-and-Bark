extends Node

const Store=preload("res://scripts/save_storage.gd")
const FaultStore=preload("res://tests/faulty_save_storage.gd")
const SettingsMenu=preload("res://scripts/shared_settings.gd")
var passed=0
var failures=[]
var folder=""
var screenshots=false

func check(ok,label):
	if ok:passed+=1;print("PASS: "+label)
	else:failures.append(label);push_error("FAIL: "+label)

func ticks(n=3):
	for i in range(n):await get_tree().physics_frame

func wall_time(milliseconds):
	var until=Time.get_ticks_msec()+milliseconds
	while Time.get_ticks_msec()<until:await get_tree().process_frame

func key(code):
	var event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true;get_tree().root.push_input(event,true);await ticks(2)
	event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=false;get_tree().root.push_input(event,true);await ticks(2)

func capture(label):
	if not screenshots:return
	await ticks(3);await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/finishing_"+label+".png")

func shared(node):
	if node.get_script()==SettingsMenu:return node
	for child in node.get_children():
		var found=shared(child)
		if found!=null:return found
	return null

func fits(node):
	var valid=true
	for child in node.get_children():
		if child is Control:
			var inside=Rect2(0,0,1280,720).grow(1).encloses(child.get_global_rect());valid=valid and inside
			if not inside:print("Outside viewport: ",child.name," ",child.get_global_rect())
		valid=valid and fits(child)
	return valid

func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS;call_deferred("run")

func test_atomic_writes():
	var store=Store.new();var path=folder+"/atomic.json"
	var first=JSON.parse_string('{"version":1,"data":{"stage":1}}');var second=JSON.parse_string('{"version":1,"data":{"stage":2}}');var third=JSON.parse_string('{"version":1,"data":{"stage":3}}')
	check(store.write_atomic(path,first,Progress.valid_document)==OK,"First save publishes a readable primary")
	check(not FileAccess.file_exists(path+".bak"),"First save does not invent an empty backup")
	check(store.write_atomic(path,second,Progress.valid_document)==OK and store.read_json(path+".bak")==first,"Next commit keeps the previous valid adventure")
	for fault in ["partial_write","silent_short_write","backup_copy","corrupt_backup","backup_publish","primary_publish"]:
		store.write_text(path,JSON.stringify(second));store.write_text(path+".bak",JSON.stringify(first))
		var failing=FaultStore.new();failing.fault=fault
		check(failing.write_atomic(path,third,Progress.valid_document)!=OK,"Save reports failure: "+fault)
		check(store.read_json(path)==second,"Failure preserves the committed primary: "+fault)
		check(store.read_json(path+".bak")== (second if fault=="primary_publish" else first),"Failure retains a valid backup: "+fault)
		check(not FileAccess.file_exists(path+".tmp") and not FileAccess.file_exists(path+".bak.tmp"),"Failed temporary files are discarded: "+fault)
	store.write_text(path,"{damaged");store.write_text(path+".bak",JSON.stringify(first))
	check(store.write_atomic(path,third,Progress.valid_document)==OK and store.read_json(path+".bak")==first,"Repairing a corrupt primary never overwrites its good backup")
	DirAccess.make_dir_absolute(path+".tmp")
	check(store.write_atomic(path,second,Progress.valid_document)!=OK and store.read_json(path)==third,"A real blocked temporary path leaves progress intact")
	DirAccess.remove_absolute(path+".tmp")

func test_story_recovery():
	Progress.save_path=folder+"/story.json";Progress.storage=Store.new();Progress.save_enabled=true;Progress._ready()
	Progress.data.stage=3;Progress.data.notebook=true;Progress.data.leaves=["leaf_1"];Progress.data.checkpoint=2700.0;Progress.tutorial_done=true
	Progress.settings=Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.merge({"volume":.35,"music":false,"reduced_motion":true,"touch":true,"painted_characters":true},true)
	check(Progress.save_game(),"Legacy-format story and shared preferences save together")
	var first=Progress.read_valid(Progress.save_path)
	Progress.data.stage=4;Progress.data.books=true;check(Progress.save_game(),"Later story progress rotates the prior save")
	Progress.storage.write_text(Progress.save_path,"{interrupted");Progress._ready()
	check(Progress.recovered_backup and Progress.data.stage==3 and Progress.data.leaves==["leaf_1"] and Progress.tutorial_done,"Damaged primary recovers story, discoveries and tutorial state")
	check(Progress.settings.volume==.35 and not Progress.settings.music and Progress.settings.touch and Progress.settings.reduced_motion,"Backup recovery also restores the shared preferences")
	var backup=FileAccess.get_file_as_bytes(Progress.save_path+".bak")
	Progress.data.plant=true;check(Progress.save_game() and not Progress.recovered_backup,"Recovered progress can be saved normally")
	check(FileAccess.get_file_as_bytes(Progress.save_path+".bak")==backup and Progress.read_valid(Progress.save_path).data.plant,"Saving after recovery preserves its good backup")
	DirAccess.remove_absolute(Progress.save_path);Progress._ready()
	check(Progress.recovered_backup and Progress.data.stage==3,"A missing primary recovers the previous adventure")
	Progress.storage.write_text(Progress.save_path+".bak",JSON.stringify({"version":99,"data":{"stage":7}}))
	Progress.storage.write_text(Progress.save_path+".tmp",JSON.stringify(first));Progress._ready()
	check(Progress.data.stage==0 and not Progress.tutorial_done and not Progress.recovered_backup,"Unsupported backup and uncommitted temporary data cannot create false progress")
	Progress.storage.write_text(Progress.save_path,JSON.stringify({"version":1,"data":{"stage":999,"attempts":-3,"checkpoint":99999,"leaves":["leaf_1","leaf_1","bad",2]},"settings":{"volume":{"bad":1},"music":"false","touch":1,"unknown":true},"tutorial_done":"yes"}));Progress._ready()
	check(Progress.data.stage==7 and Progress.data.attempts==0 and Progress.data.checkpoint==5400 and Progress.data.leaves==["leaf_1"],"Legacy malformed values are bounded and discoveries deduplicated")
	check(Progress.settings==Progress.SETTING_DEFAULTS and not Progress.tutorial_done,"Malformed preferences recover to typed defaults")
	check(not Progress.set_setting("unknown",true) and not Progress.set_setting("volume",NAN) and not Progress.set_setting("music","false"),"Unknown, non-finite and incorrectly typed preferences are rejected")
	var committed=FileAccess.get_file_as_bytes(Progress.save_path)
	var failing=FaultStore.new();failing.fault="partial_write";Progress.storage=failing;Progress.data.stage=4
	check(not Progress.save_game() and not Progress.last_save_ok and Progress.last_save_error!=OK,"Story save failures are observable by the interface")
	check(FileAccess.get_file_as_bytes(Progress.save_path)==committed and Progress.data.stage==4,"A failed save keeps both the committed file and the current session")
	Progress.storage=Store.new();check(Progress.save_game() and Progress.last_save_ok,"Successful retry clears the save failure")

func check_failed_close(game,label):
	var failing=FaultStore.new();failing.fault="partial_write";Progress.storage=failing
	var before=Progress.data.duplicate(true)
	game.request_quit();await ticks(3)
	check(is_instance_valid(game.quit_prompt) and get_tree().paused,label+": failed close keeps the adventure open")
	check(get_viewport().gui_get_focus_owner()==game.quit_prompt.keep_button,label+": failed close defaults to keeping progress open")
	check(fits(game.quit_prompt),label+": recovery choices fit the screen")
	if label=="Home":await capture("save_failure")
	game.quit_prompt.keep_button.pressed.emit();await ticks(3)
	check(not get_tree().paused and Progress.data==before,label+": Keep playing resumes the same session")
	Progress.storage=Store.new();Progress.save_game()

func run():
	get_tree().current_scene=null
	await ticks();get_tree().root.size=Vector2i(1280,720)
	screenshots="--screenshots" in OS.get_cmdline_user_args();DirAccess.make_dir_recursive_absolute("res://test_output")
	folder="user://finishing_review_"+str(Time.get_ticks_usec());DirAccess.make_dir_recursive_absolute(folder)
	Mega.save_path=folder+"/climbs.json";Mega.storage=Store.new();Mega.enabled=true;Mega._ready()
	test_atomic_writes();test_story_recovery()
	Progress.settings=Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.characters_3d=false # This suite retains explicit legacy appearance-control coverage.
	Progress.reset_game(false);Progress.tutorial_done=true;Progress.data.shrunken=true;Progress.data.stage=4;Progress.data.notebook=true;Progress.data.plant=true;Progress.data.plant_restored=true;Progress.data.books=true;Progress.data.pencil=true;Progress.data.checkpoint=4490.0;Progress.save_game()
	Mega.intro_done=true;Mega.runs[0].checkpoint=3;Mega.runs[0].leaves=[0,3,8];Mega.save()
	var story_before=Progress.data.duplicate(true);var climbs_before=Mega.runs.duplicate(true)
	var original=load("res://assets/campus_music.wav");var original_mode=original.loop_mode
	await Adventures.go(Adventures.HOME);var home=get_tree().current_scene;await ticks(5)
	check(home.music_player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and home.music_player.stream.loop_end>0,"First-visit menu music has its own complete loop")
	check(original.loop_mode==original_mode and home.music_player.stream!=original,"Menu looping does not mutate the shared imported audio")
	var ended={"count":0};home.music_player.finished.connect(func():ended.count+=1)
	home.music_player.seek(home.music_player.stream.get_length()-.10);await wall_time(450)
	check(home.music_player.playing and ended.count==0 and home.music_player.get_playback_position()<1.0,"Menu music actually wraps past the end without stopping")
	home.show_settings();await ticks(5);var menu=shared(home.settings_overlay)
	check(menu!=null and menu.toggles.size()==SettingsMenu.LABELS.size() and fits(home.settings_overlay),"Home exposes the complete shared settings in a bounded panel")
	menu.volume_slider.value=.35
	check(menu.volume_label.text=="35%" and absf(home.music_player.volume_db-linear_to_db(.35*.28))<.01,"Volume feedback and live menu gain update immediately")
	menu.toggles.music.button_pressed=false;await ticks()
	check(home.music_player.stream_paused and not Progress.settings.music,"Music toggle immediately pauses the menu loop")
	menu.toggles.music.button_pressed=true;menu.volume_slider.value=0
	check(home.music_player.stream_paused and home.music_player.volume_db<=-79,"Master mute also silences the live menu")
	menu.volume_slider.value=.35;menu.toggles.reduced_motion.button_pressed=true;menu.toggles.touch.button_pressed=true;menu.toggles.painted_characters.button_pressed=false;menu.toggles.calm.button_pressed=true;await ticks()
	check(home.mark.mesh.visible and not Progress.settings.painted_characters and not home.paint_toggle.button_pressed,"Shared appearance setting updates both the character and home toggle")
	home.paint_toggle.button_pressed=true;await ticks()
	check(menu.toggles.painted_characters.button_pressed and not home.mark.mesh.visible,"Home appearance toggle synchronizes the open settings without feedback loops")
	await capture("home_settings");await key(KEY_ESCAPE)
	check(not is_instance_valid(home.settings_overlay) and get_viewport().gui_get_focus_owner()==home.settings_button,"Escape closes home settings and restores useful focus")
	Progress._ready();Mega._ready()
	check(is_equal_approx(Progress.settings.volume,.35) and Progress.settings.touch and Progress.settings.reduced_motion and Progress.settings.painted_characters and Mega.prefs.calm,"Shared preferences survive a cold reload")
	check(Progress.data==story_before and Mega.runs==climbs_before,"Preference writes and reload preserve both adventures")
	await check_failed_close(home,"Home")
	await Adventures.go(Adventures.STORY,"start_continue");var story=get_tree().current_scene;await ticks(8)
	story.show_settings(story.close_modal);await ticks(5);menu=shared(story.modal)
	check(menu!=null and is_equal_approx(menu.volume_slider.value,.35) and menu.toggles.calm.button_pressed and fits(story.modal),"Story uses the same saved controls, including climb preferences")
	menu.toggles.music.button_pressed=false;await ticks(3)
	check(story.soundscape.music.stream_paused,"Shared music control reaches the story soundscape")
	await capture("story_settings");await key(KEY_ESCAPE)
	check(not story.busy and story.player.enabled and story.touch_root.visible,"Leaving shared story settings resumes play with touch preference applied")
	await check_failed_close(story,"Story")
	await Adventures.go(Adventures.CLIMBS,"start");var climbs=get_tree().current_scene;await ticks(8)
	climbs.settings(climbs.close);await ticks(5);menu=shared(climbs.panel)
	check(menu!=null and not menu.toggles.music.button_pressed and menu.toggles.touch.button_pressed and fits(climbs.panel),"Climbing settings reflect changes made in the story")
	menu.volume_slider.value=.55;menu.toggles.reduced_motion.button_pressed=false;menu.toggles.touch.button_pressed=false;await ticks(3)
	check(is_equal_approx(Progress.settings.volume,.55) and not climbs.player.reduced_motion,"Shared reduced-motion preference reaches the climbing player")
	await capture("climb_settings");await key(KEY_ESCAPE)
	if climbs.busy or not climbs.player.enabled or climbs.touch_root.visible:print("Climb return state: ",climbs.busy," ",climbs.player.enabled," touch ",climbs.touch_root.visible," mode ",climbs.mode," preference ",Progress.settings.touch," touch mode ",climbs.touch_mode)
	check(not climbs.busy and climbs.player.enabled and not climbs.touch_root.visible,"Climbing settings return cleanly to the same level")
	await check_failed_close(climbs,"Climbs")
	await Adventures.go(Adventures.HOME);home=get_tree().current_scene;await ticks()
	check(home.music_player.stream_paused and not Progress.settings.music,"Returning home respects music disabled in another adventure")
	home.show_settings();await ticks(4);menu=shared(home.settings_overlay)
	check(is_equal_approx(menu.volume_slider.value,.55) and not menu.toggles.touch.button_pressed and not menu.toggles.reduced_motion.button_pressed,"Every entrance shows the same latest preferences")
	check(Progress.data==story_before and Mega.runs==climbs_before,"Scene switches and failed closes do not reset either adventure")
	check(Art.missing_assets.is_empty(),"Finishing flows request no missing artwork")
	await capture("return_settings");home.close_settings();await home.drain_audio()
	print("FINISHING RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
