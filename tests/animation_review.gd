extends Node
var passed=0
var failures=[]
var screenshots=false
func check(ok,label):
	if ok:passed+=1;print("PASS: "+label)
	else:failures.append(label);push_error("FAIL: "+label)
func ticks(n=2):
	for i in range(n):await get_tree().physics_frame
func capture(label):
	if not screenshots:return
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/animation_"+label+".png")
func key(code):
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=true;get_tree().root.push_input(e,true);await ticks(2)
	e=InputEventKey.new();e.physical_keycode=code;e.pressed=false;get_tree().root.push_input(e,true);await ticks(2)
func _ready():call_deferred("run")
func run():
	await ticks(3);screenshots="--screenshots" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://test_output")
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=false
	var holder=Node2D.new();add_child(holder)
	for role in ["young","bark"]:
		var actor=Art.character(role+"_actions_idle");holder.add_child(actor);await ticks(3)
		check(actor.skeleton is Skeleton2D and actor.bones.size()==26,role+": native body and facial skeleton exists")
		check(actor.mesh.texture==actor.texture and actor.mesh.skeleton==NodePath("../Skeleton2D"),role+": original paint is bound to its native skeleton")
		check(actor.offset==Vector2(-256,-612),role+": supplied foot pivot is preserved")
		for id in actor.profiles:
			if actor.profiles[id].role!=("mark" if role=="young" else "bark"):continue
			actor.texture=Art.tex(id);actor.drive("idle",true);actor.sync_pose();await ticks(1)
			var valid=true
			for p in actor.rest_points.values():valid=valid and p.is_finite()
			for vertex in range(actor.base_vertices.size()):
				var sum=0.0;var influences=0
				for values in actor.bone_weights.values():
					sum+=values[vertex]
					if values[vertex]>.00001:influences+=1
				valid=valid and absf(sum-1)<.0001 and influences<=4
			check(valid and actor.mesh.visible and actor.self_modulate.a==0,id+": finite points, complete normalized skin and intact painted mesh")
		actor.texture=Art.tex(role+"_actions_idle");actor.drive("idle",true);await ticks(5)
		var old_head=actor.bones.Head.rotation;var old_root=actor.bones.Hip.position;await ticks(24)
		check(absf(actor.bones.Head.rotation-old_head)>.0001 and actor.bones.Hip.position.distance_to(old_root)>.01,role+": idle breath and head motion are independent")
		check(is_equal_approx(actor.weights_at(Vector2(256,612),true).get("FootLock",0),1.0) and actor.joint_position("origin").length()<.001,role+": standing foot anchor stays fully pinned")
		actor.texture=Art.tex(role+"_actions_"+("jump" if role=="young" else "hop"));actor.drive("spring_release",false,Vector2(200,-450));await ticks(20)
		check(absf(actor.bones.ShoulderNear.rotation)>.03 and absf(actor.bones.ElbowNear.rotation)>.01 and absf(actor.bones.KneeNear.rotation)>.02,role+": launch articulates shoulders, elbows and knees")
		check(absf(actor.bones.AnkleNear.rotation)>.01 and absf(actor.bones.ToeNear.rotation)>.001,role+": airborne ankles and toes follow the launch")
		check(actor.weights_at(Vector2(256,612),false).get("FootLock",0.0)==0,role+": airborne feet can articulate freely")
		actor.texture=Art.tex(role+"_actions_idle");actor.drive("talk",true);await ticks(30)
		var jaw_min=9.0;var jaw_max=0.0;var blink_max=0.0
		for n in range(275):
			await ticks(1);var jaw=actor.bones.Mouth.scale.y;jaw_min=minf(jaw_min,jaw);jaw_max=maxf(jaw_max,jaw);blink_max=maxf(blink_max,1-actor.bones.EyeNear.scale.y)
		check(jaw_max-jaw_min>.12,role+": talking changes the mouth independently")
		check(blink_max>.80,role+": natural blink closes and reopens the eyelids")
		check(actor.face_material.get_shader_parameter("face_enabled")==true,role+": calibrated facial shader is active")
		var before=actor.age;var shoulder=actor.bones.ShoulderNear.transform;actor.frozen=true;await ticks(15)
		check(actor.age==before and actor.bones.ShoulderNear.transform==shoulder,role+": pause freezes all motion channels")
		actor.frozen=false;Progress.settings.reduced_motion=true;await ticks(2)
		var still=true
		for bone in actor.bones.values():still=still and bone.transform.is_equal_approx(bone.rest)
		check(still and actor.face_material.get_shader_parameter("face_enabled")==false,role+": reduced motion rests every body and face channel")
		Progress.settings.reduced_motion=false;actor.reset_motion();await ticks(2)
		check(actor.mode=="idle" and actor.emote_left==0 and actor.landing_age>=9,role+": resets clear the previous launch and emote")
		actor.queue_free();await ticks(2)
	holder.queue_free();await ticks(2)
	check(Art.tex("young_actions_cheer")==Art.tex("young_actions_jump"),"Legacy cheer keeps Mark's identity instead of a missing-texture square")
	var game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(5);game.load_level(0);await ticks(15)
	check(game.player.sprite.has_method("drive") and game.campus.bark.has_method("drive"),"Both game actors use the articulated rig")
	check(not game.player.ghost.has_method("drive"),"Pose crossfade uses one lightweight ghost instead of a second skeleton")
	game.fingers[-3]="right";var poses={}
	for n in range(40):await ticks(1);poses[game.campus.bark.texture.resource_path]=true
	check(poses.size()>=3,"Bark cycles multiple stride poses while following Mark")
	game.fingers.clear();game.retry();await ticks(10);game.jump();await ticks(24);game.jump();await ticks(2)
	check(game.player.sprite.mode=="spring_contact" and game.campus.bark.mode=="spring_contact","Real second jump drives coordinated contact channels")
	check(game.player.leaf_bursts.size()==1 and game.player.air_rings.size()==1,"Spring adds a restrained leaf burst and launch ring")
	var at=game.player.leaf_bursts[0].at;await ticks(8)
	check(game.player.leaf_bursts[0].at==at,"Leaves remain anchored at the launch instead of travelling with Mark")
	await capture("team_release")
	check(game.player.sprite.mode=="spring_release" and game.campus.bark.mode=="spring_release","Contact flows into separate release channels")
	game.pause_game();await ticks(2);var mark_age=game.player.sprite.age;var bark_age=game.campus.bark.age;await ticks(20)
	check(game.player.sprite.age==mark_age and game.campus.bark.age==bark_age,"Game pause freezes both native skeletons")
	game.close();await ticks(100)
	check(game.player.is_on_floor() and game.player.sprite.landing_force>0 and game.campus.bark.landing_force>0,"Both friends settle through their own joints after a real landing")
	game.retry();await ticks(2)
	check(game.player.leaf_bursts.is_empty() and game.player.sprite.emote_left==0,"Checkpoint clears flourish effects and stale body poses")
	game.say(["Mark|I think this might actually work.","Bark|An alarming development!"]);await ticks(10)
	check(game.dialogue_portrait.actor.texture==Art.tex("young_actions_notebook") and game.dialogue_portrait.actor.mode=="talk","Mark's dialogue portrait uses his live talking rig")
	game.next_line();await ticks(10)
	check(game.dialogue_portrait.actor.texture==Art.tex("bark_actions_hint") and game.dialogue_portrait.actor.role=="bark","Dialogue switches to Bark's calibrated face and gesture")
	await capture("portrait");game.end_dialogue()
	await key(KEY_F8);check(game.player.sprite.show_points and game.campus.bark.show_points,"F8 reveals both actors' joint overlays in game")
	await key(KEY_F8);check(not game.player.sprite.show_points and not game.campus.bark.show_points,"F8 hides the inspection overlay cleanly")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(5)
	var studio=load("res://scenes/animation_studio.tscn").instantiate();add_child(studio);await ticks(5)
	var fits=true
	for control in studio.get_children():
		if control is Control:
			var inside=Rect2(0,0,1280,720).encloses(control.get_global_rect());fits=fits and inside
			if not inside:print("Outside studio: ",control.name," ",control.get_global_rect())
	check(studio.mark.bones.size()==26 and studio.bark.bones.size()==26 and fits,"Animation studio loads both complete rigs with controls inside the screen")
	await key(KEY_6);check(studio.current==5 and studio.mark.mode=="talk","Studio keyboard selects the facial performance")
	await key(KEY_SPACE);var age=studio.mark.age;await ticks(10);check(studio.paused and studio.mark.age==age,"Studio pause holds the pose for inspection")
	studio.next_frame();check(studio.paused and studio.mark.age>age,"Frame advance moves exactly while inspection remains paused")
	studio.toggle_speed();check(studio.mark.playback_rate==.5 and studio.bark.playback_rate==.5,"Studio slow motion controls both characters together")
	await key(KEY_P);check(studio.mark.show_points and studio.bark.show_points,"Studio joint inspection is keyboard accessible")
	await capture("studio_joints");studio.toggle_points();studio.choose(6);studio.toggle_pause();await ticks(20);await capture("studio_cheer")
	studio.queue_free();await ticks(3)
	print("ANIMATION RESULT: ",passed," passed; ",failures.size()," failed");get_tree().quit(0 if failures.is_empty() else 1)
