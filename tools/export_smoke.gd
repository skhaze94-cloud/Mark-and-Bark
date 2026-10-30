extends SceneTree

# External test controller: deliberately excluded from the production PCK.
class FailedWrite extends RefCounted:
	func write_atomic(_path,_document,_validator):return ERR_FILE_CANT_WRITE

var passed=0
var failures=[]
var report_path=""
var state_folder=""
var phase=""

func check(ok,label):
	if ok:passed+=1;print("PASS: "+label)
	else:failures.append(label);push_error("FAIL: "+label)

func ticks(n=3):
	for i in range(n):await physics_frame

func shared(node):
	if node.name=="SharedSettings" and node.has_method("return_from_settings"):return node
	for child in node.get_children():
		var found=shared(child)
		if found!=null:return found
	return null

func _initialize():call_deferred("run")

func run():
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--state-dir="):state_folder=argument.trim_prefix("--state-dir=")
		elif argument.begins_with("--report="):report_path=argument.trim_prefix("--report=")
		elif argument.begins_with("--phase="):phase=argument.trim_prefix("--phase=")
	if not state_folder.is_absolute_path() or not report_path.is_absolute_path() or phase not in ["seed","resume","recover"]:
		push_error("Export verification needs an isolated state directory, report and phase.");quit(2);return
	DirAccess.make_dir_recursive_absolute(state_folder);await ticks()
	var progress=root.get_node("Progress");var mega=root.get_node("Mega");var nav=root.get_node("Adventures");var art=root.get_node("Art")
	progress.save_path=state_folder.path_join("story.json");mega.save_path=state_folder.path_join("climbs.json")
	progress._ready();mega._ready();progress.save_enabled=true;mega.enabled=true
	check(not ResourceLoader.exists("res://tests/finishing_review.gd") and not FileAccess.file_exists("res://tools/verify_exports.py") and not FileAccess.file_exists("res://docs/RESTORATION_AUDIT_3_2_1.md"),"Production export excludes tests, tooling and review documents")
	for path in ["res://assets/index.json","res://assets/rigs/character_points.json","res://assets/variety/regions.json","res://assets/FONT_LICENSE.txt"]:
		check(FileAccess.file_exists(path),"Export includes runtime data: "+path)
	if phase=="seed":
		progress.reset_game(false);progress.tutorial_done=true;progress.data.shrunken=true;progress.data.stage=4;progress.data.notebook=true;progress.data.plant=true;progress.data.plant_restored=true;progress.data.books=true;progress.data.pencil=true;progress.data.checkpoint=4490.0
		mega.reset(false);mega.unlocked=3;mega.intro_done=true;mega.runs[0].checkpoint=3;mega.runs[0].leaves=[0,3,8]
		check(progress.save_game() and mega.save(),"Export can save both adventures outside its resource pack")
	else:
		check(progress.data.stage==4 and progress.tutorial_done and mega.runs[0].checkpoint==3 and mega.runs[0].leaves==[0,3,8] and 0 in mega.runs[0].get("wonders",[]),"Export reloads progress and optional wonders from a previous process")
		check(is_equal_approx(progress.settings.volume,.35) and not progress.settings.music and progress.settings.touch and progress.settings.characters_3d and mega.prefs.calm,"Export reloads the shared preferences")
		if phase=="recover":check(progress.recovered_backup and mega.recovered_backup,"A fresh exported process recovers both damaged primary saves")
	var story_before=progress.data.duplicate(true)
	await nav.go(nav.HOME);var home=current_scene;await ticks(4)
	check(home.music_player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Exported opening menu uses the corrected audio loop")
	home.show_settings();await ticks(4);var menu=shared(home.settings_overlay)
	check(menu!=null and menu.toggles.size()==5,"Exported home exposes the shared settings")
	menu.volume_slider.value=.35;menu.toggles.music.button_pressed=false;menu.toggles.touch.button_pressed=true;menu.toggles.reduced_motion.button_pressed=true;menu.toggles.painted_characters.button_pressed=true;menu.toggles.calm.button_pressed=true;menu.select_character_style(0)
	menu.back_button.pressed.emit();await ticks(3)
	check(home.music_player.stream_paused and is_equal_approx(progress.settings.volume,.35),"Export applies mute and volume without restarting the scene")
	check(home.mark.character3d.active and home.bark.character3d.active,"Exported home renders both genuine3D character models")
	for friend in [home.mark,home.bark]:
		var rig=friend.character3d.model.soft_skin
		check(rig is Skeleton3D and rig.get_bone_count()>=12 and rig.surfaces.size()>=4 and rig.surfaces.all(func(p):return p.skin!=null),"Export contains weighted character surfaces and their real skeleton")
	await nav.go(nav.STORY,"start_continue");var story=current_scene;await ticks(6)
	check(story.mode=="campus" and story.campus.backgrounds.size()==3 and story.campus.board!=null,"Export enters the full painted story with its invention board")
	check(story.player.sprite.texture!=null and story.player.sprite.character3d.active and not story.player.sprite.mesh.visible,"Export renders3D characters while retaining original source artwork")
	story.show_settings(story.close_modal);await ticks(3);menu=shared(story.modal)
	check(menu!=null and menu.toggles.touch.button_pressed and not menu.toggles.music.button_pressed,"Exported story uses the same persisted settings")
	menu.select_character_style(1);await ticks(2)
	check(not story.player.sprite.character3d.active and story.player.sprite.self_modulate.a==1.0,"Export can select the complete original painted style")
	menu.select_character_style(0);await ticks(2)
	check(story.player.sprite.character3d.active,"Export can restore3D presentation without changing the adventure")
	menu.back_button.pressed.emit();await ticks()
	await nav.go(nav.CLIMBS,"start");var climbs=current_scene;await ticks(5)
	for i in range(3):
		climbs.load_level(i);await ticks(3)
		if i==0:
			var wonders=climbs.campus.little_wonders
			check(wonders!=null and wonders.entries.size()==3,"Export includes all three opening-stage miniature encounters")
			climbs.player.position=wonders.entries[0].at+Vector2(85,-3);climbs.player.velocity=Vector2.ZERO;await ticks(8)
			climbs.interact();await ticks(2)
			check(0 in mega.runs[0].wonders and not climbs.busy,"Exported Use discovers a tiny life without blocking play")
		check(climbs.campus.RISES[i].size()==[24,27,33][i] and climbs.campus.ledges[0].atlas!=null,"Export loads the painted platforms for climb "+str(i+1))
	climbs.settings(climbs.close);await ticks(3);menu=shared(climbs.panel)
	check(menu!=null and menu.toggles.calm.button_pressed,"Exported climbs share the calm-climb preference")
	menu.back_button.pressed.emit();await ticks()
	await nav.go(nav.STUDIO);var studio=current_scene;await ticks(3)
	check(studio.mark.character3d.active and studio.bark.character3d.active,"Export retains the complete3D character studio")
	progress.set_setting("reduced_motion",false,false)
	studio.toggle_turntable();await ticks(4)
	check(studio.mark.character3d.inspection_yaw>0 and studio.bark.character3d.inspection_yaw>0,"Exported studio inspects actual3D volume on the turntable")
	progress.set_setting("reduced_motion",true,false)
	await nav.go(nav.HOME);home=current_scene;await ticks()
	check(progress.data==story_before and art.missing_assets.is_empty(),"Exported navigation preserves story progress and resolves its artwork")
	var normal_store=progress.storage;progress.storage=FailedWrite.new()
	home.request_quit();await ticks(3)
	check(paused and is_instance_valid(home.quit_prompt),"Exported close protects unsaved progress after a failed write")
	home.quit_prompt.keep_button.pressed.emit();await ticks(3)
	check(not paused and not home.closing,"Exported Keep playing returns to the existing session")
	home.request_quit();await ticks(3);progress.storage=normal_store
	check(is_instance_valid(home.quit_prompt) and paused,"Exported failed close remains retryable")
	var report={"phase":phase,"engine":Engine.get_version_info().string,"platform":OS.get_name(),"passed":passed,"failed":failures.size(),"failures":failures,"release":ProjectSettings.get_setting("application/config/version"),"exit_retry_requested":failures.is_empty()}
	var file=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("EXPORT RESULT: ",passed," passed; ",failures.size()," failed")
	if not failures.is_empty():paused=false;home.stop_audio();quit(1);return
	# The real production close handler performs the successful retry and exits.
	home.quit_prompt.retry_button.pressed.emit()
