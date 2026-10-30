extends Node
## Geometry, actual joint performance, renderer choices and real-world integration.
## A native display adds alpha/silhouette checks and real 3D/world screenshots.
const Store = preload("res://scripts/save_storage.gd")
const JOINTS = ["hips", "head", "shoulder_near", "elbow_near", "wrist_near", "shoulder_far", "elbow_far", "wrist_far", "knee_near", "ankle_near", "knee_far", "ankle_far"]
var passed = 0
var failures = []
var screenshots = false
var finished = false

func check(ok, message):
	if ok:
		passed += 1
		print("PASS: " + message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func ticks(count = 3):
	for i in range(count):
		await get_tree().physics_frame
	# process_frame fires before actor _process; slow native rendering can run
	# several physics ticks before one visual update. Let that update complete.
	await get_tree().process_frame
	await get_tree().process_frame

func _ready():
	Progress.save_enabled = false
	Mega.enabled = false
	screenshots = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://test_output")
	var watchdog = Timer.new()
	watchdog.wait_time = 180
	watchdog.one_shot = true
	watchdog.timeout.connect(func():
		if not finished:
			check(false, "Character 2.0 review completes within 180 seconds")
			finish()
	)
	add_child(watchdog)
	watchdog.start()
	call_deferred("run")

func finish():
	if finished:
		return
	finished = true
	print("CHARACTER 3D RESULT: ", passed, " passed; ", failures.size(), " failed")
	get_tree().quit(0 if failures.is_empty() else 1)

func capture(name):
	if not screenshots:
		return
	await ticks(3)
	await RenderingServer.frame_post_draw
	var image = get_tree().root.get_texture().get_image()
	check(image != null and not image.is_empty(), "Native character viewport renders " + name)
	if image == null or image.is_empty():
		return
	check(image.save_png("res://test_output/character3d_" + name + ".png") == OK, "Character screenshot saves " + name)

func descendants(node):
	var result = [node]
	for child in node.get_children():
		result.append_array(descendants(child))
	return result

func meshes(model):
	return descendants(model).filter(func(node): return node is MeshInstance3D and node.mesh != null)

func collision_free(node):
	return descendants(node).all(func(child): return not child is CollisionObject2D and not child is CollisionShape2D and not child is CollisionObject3D and not child is CollisionShape3D)

func transform_snapshot(model):
	var result = {}
	for node in descendants(model):
		if node is Node3D:
			result[str(model.get_path_to(node))] = node.transform
	return result

func model_bounds(model):
	var first = true
	var result = AABB()
	for part in meshes(model):
		var bounds: AABB = part.mesh.get_aabb()
		var relative: Transform3D = model.global_transform.affine_inverse() * part.global_transform
		for corner in range(8):
			var point: Vector3 = relative * bounds.get_endpoint(corner)
			if first:
				result = AABB(point, Vector3.ZERO)
				first = false
			else:
				result = result.expand(point)
	return result

func renderer(actor, label):
	var presenter = actor.get("character3d")
	check(is_instance_valid(presenter) and presenter.active, label + " selects the genuine 3D renderer")
	if not is_instance_valid(presenter) or not presenter.active:
		return null
	check(presenter.viewport is SubViewport and presenter.viewport.transparent_bg and presenter.viewport.own_world_3d, label + " renders in an isolated transparent 3D world")
	check(presenter.camera is Camera3D and presenter.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, label + " uses a real orthographic 3D camera")
	check(is_instance_valid(presenter.model) and is_instance_valid(presenter.performance) and collision_free(presenter), label + " adds display geometry without gameplay collision")
	return presenter

func alpha_bounds(image):
	var minimum = Vector2i(image.get_width(), image.get_height())
	var maximum = Vector2i(-1, -1)
	var count = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
				count += 1
	return {"rect": Rect2i(minimum, maximum - minimum + Vector2i.ONE) if count else Rect2i(), "count": count}

func native_silhouette(actor, label):
	if not screenshots:
		return
	await ticks(3)
	await RenderingServer.frame_post_draw
	var view = actor.character3d.viewport
	var image = view.get_texture().get_image()
	check(image != null and not image.is_empty(), label + " produces an actual 3D render texture")
	if image == null or image.is_empty():
		return
	var ink = alpha_bounds(image)
	var source = alpha_bounds(actor.texture.get_image())
	var rect: Rect2i = ink.rect
	check(ink.count > 1000 and rect.size.x > 60 and rect.size.y > 120, label + " has a substantial nonempty character silhouette")
	check(rect.position.x > 2 and rect.position.y > 2 and rect.end.x < image.get_width() - 2 and rect.end.y < image.get_height() - 2, label + " keeps the complete head, limbs and feet inside its render texture")
	check(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a < 0.01, label + " keeps the surrounding painted world visible through transparent corners")
	# Compare normalized source-space dimensions so a smaller viewport is valid.
	var height_ratio: float = (float(rect.size.y) / image.get_height()) / (float(source.rect.size.y) / actor.texture.get_height())
	var width_ratio: float = (float(rect.size.x) / image.get_width()) / (float(source.rect.size.x) / actor.texture.get_width())
	print("CHARACTER SIZE: ", label, " height=", height_ratio, " width=", width_ratio, " bounds=", rect)
	check(height_ratio >= 0.9 and height_ratio <= 1.55 and width_ratio >= 0.7, label + " gains solid presence without a giant or thin replacement silhouette")

func native_pose_margins(actor, label):
	if not screenshots:
		return
	await ticks(3)
	await RenderingServer.frame_post_draw
	var image = actor.character3d.viewport.get_texture().get_image()
	var ink = alpha_bounds(image)
	var rect: Rect2i = ink.rect
	check(ink.count > 1000 and rect.position.x > 2 and rect.position.y > 2 and rect.end.x < image.get_width() - 2 and rect.end.y < image.get_height() - 2, label + " keeps raised hands, head and feet completely inside its real render texture")

func review_actor(role):
	var source_id = "young_actions_idle" if role == "mark" else "bark_actions_idle"
	var actor = Art.game_actor(source_id)
	actor.position = Vector2(350 if role == "mark" else 930, 650)
	actor.scale = Vector2.ONE * (0.7 if role == "mark" else 0.85)
	add_child(actor)
	await ticks(8)
	var presenter = renderer(actor, role)
	if presenter == null:
		actor.queue_free()
		await ticks()
		return
	var model = presenter.model
	var pieces = meshes(model)
	var bounds: AABB = model_bounds(model)
	var solid_parts = pieces.filter(func(part):
		var extent: Vector3 = part.mesh.get_aabb().size * part.scale.abs()
		return extent.x > 0.015 and extent.y > 0.015 and extent.z > 0.015
	)
	check(pieces.size() >= 12 and solid_parts.size() >= 8 and bounds.size.y > 1.0 and bounds.size.z > 0.2, role + " is built from real volumetric head/body/limb geometry")
	check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.position.y > -0.2, role + " has finite model bounds and feet close to the supporting plane")
	var joints: Dictionary = model.joints
	check(JOINTS.all(func(key): return joints.has(key) and joints[key] is Node3D), role + " has articulated 3D head, body, arm and leg pivots")
	check(actor.texture == Art.tex(source_id) and not actor.mesh.visible, role + " preserves its original source artwork without drawing a duplicate 2D mesh")
	check(presenter.projected_joint("origin").distance_to(Vector2.ZERO) < 1.0, role + " keeps the projected foot anchor fixed at its 2D world origin")
	check(JOINTS.all(func(key): return presenter.projected_joint(key).is_finite() and actor.joint_position(key).distance_to(presenter.projected_joint(key)) < 0.01), role + " inspection points project the real 3D joints into the world overlay")
	var node_count = descendants(presenter).size()
	var mesh_count = pieces.size()
	actor.drive("idle", true)
	var idle_before = transform_snapshot(model)
	await ticks(30)
	check(transform_snapshot(model) != idle_before, role + " idle performance changes actual 3D transforms")
	actor.drive("run", true, Vector2(260, 0), 1.4)
	await ticks(12)
	var running = transform_snapshot(model)
	actor.drive("spring_release", false, Vector2(160, -500), 2.1)
	actor.pulse("jump", 0.4)
	await ticks(10)
	check(transform_snapshot(model) != running, role + " jump performance changes the articulated 3D pose")
	actor.drive("talk", true)
	await ticks(10)
	var talking = transform_snapshot(model)
	await ticks(50)
	check(transform_snapshot(model) != talking, role + " talk and expression channels perform in the real model")
	actor.frozen = true
	await ticks(3)
	var frozen = transform_snapshot(model)
	var old_age = actor.age
	await ticks(18)
	check(transform_snapshot(model) == frozen and actor.age == old_age, role + " pause freezes body and facial geometry")
	actor.drive("idle", true)
	actor.reset_motion()
	actor.frozen = false
	Progress.settings.reduced_motion = true
	await ticks(5)
	var still = transform_snapshot(model)
	await ticks(20)
	check(transform_snapshot(model) == still, role + " reduced-motion idle rests the 3D performance")
	Progress.settings.reduced_motion = false
	actor.frozen = false
	actor.reset_motion()
	await ticks(4)
	var old_basis: Basis = model.global_basis
	var old_yaw: float = presenter.facing_yaw
	actor.scale.x = -absf(actor.scale.x)
	await ticks(20)
	check(not model.global_basis.is_equal_approx(old_basis) and absf(presenter.facing_yaw - old_yaw) > 0.2, role + " turns real geometry instead of only mirroring a flat painting")
	check(presenter.projected_joint("origin").distance_to(Vector2.ZERO) < 1.0, role + " turning preserves the supporting-surface foot anchor")
	actor.scale.x = absf(actor.scale.x)
	await ticks(20)
	var inspection_scale: Vector2 = actor.scale
	actor.scale = Vector2.ONE * 0.28
	await ticks(4)
	check(presenter.viewport.size == presenter.GAMEPLAY_RENDER_SIZE and presenter.projected_joint("origin").distance_to(Vector2.ZERO) < 1.0, role + " adapts small gameplay renders while preserving the exact supporting-surface anchor")
	actor.scale = inspection_scale
	await ticks(4)
	check(presenter.viewport.size == presenter.RENDER_SIZE and presenter.projected_joint("origin").distance_to(Vector2.ZERO) < 1.0, role + " restores close inspection resolution without moving the feet")
	actor.hide()
	await ticks(3)
	check(presenter.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, role + " stops the 3D render while its actor is hidden")
	actor.show()
	await ticks(3)
	check(presenter.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, role + " resumes the live 3D render when its actor becomes visible")
	actor.frozen = true
	await ticks(3)
	check(descendants(presenter).size() == node_count and meshes(model).size() == mesh_count, role + " repeated poses and turns do not grow the model or scene")
	await native_silhouette(actor, role)
	await capture(role + "_model")
	actor.show_points = true
	await ticks(3)
	await capture(role + "_joints")
	actor.show_points = false
	Progress.settings.characters_3d = false
	Progress.settings.painted_characters = true
	await ticks(4)
	check(not presenter.active and actor.self_modulate.a == 1 and actor.texture == Art.tex(source_id) and not actor.mesh.visible, role + " can still select the exact original painted renderer")
	check(presenter.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, role + " stops rendering an inactive 3D viewport")
	Progress.settings.painted_characters = false
	await ticks(3)
	check(actor.mesh.visible and actor.self_modulate.a == 0, role + " retains the legacy articulated painting option")
	Progress.settings.characters_3d = true
	await ticks(4)
	check(presenter.active and not actor.mesh.visible, role + " returns to 3D immediately without replacing its identity")
	var fallback = ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	actor.texture = fallback
	await ticks(3)
	check(not presenter.active and actor.profile.is_empty() and not actor.mesh.visible and actor.self_modulate.a == 1 and actor.texture == fallback, role + " displays an unfamiliar source texture instead of leaving a stale 3D character active")
	actor.texture = Art.tex(source_id)
	await ticks(3)
	check(presenter.active and not actor.mesh.visible, role + " recovers its 3D presentation after an unfamiliar texture")
	actor.queue_free()
	await ticks(4)

func review_settings():
	var home = load(Adventures.HOME).instantiate()
	add_child(home)
	await ticks(6)
	check(home.mark.character3d.active and home.bark.character3d.active, "Opening menu presents both 3D friends by default")
	home.show_settings()
	await ticks(4)
	var menu
	for node in descendants(home.settings_overlay):
		if node.has_method("select_character_style"):
			menu = node
	check(is_instance_valid(menu) and menu.style_selector.item_count == 3, "All three character presentations have an explicit style selector")
	if is_instance_valid(menu):
		menu.select_character_style(1)
		await ticks(4)
		check(not Progress.settings.characters_3d and Progress.settings.painted_characters and not home.mark.character3d.active, "Original painting selection synchronizes both renderer preferences")
		menu.select_character_style(2)
		await ticks(4)
		check(not Progress.settings.characters_3d and not Progress.settings.painted_characters and home.mark.mesh.visible, "Articulated painting remains a working separate choice")
		menu.select_character_style(0)
		await ticks(4)
		check(Progress.settings.characters_3d and home.mark.character3d.active and home.bark.character3d.active, "3D selection updates both friends while Settings remains open")
	home.close_settings()
	await ticks(3)
	await capture("opening_menu")
	await home.drain_audio()
	home.queue_free()
	await ticks(4)
	var saved_path = Progress.save_path
	var saved_store = Progress.storage
	var saved_data = Progress.data.duplicate(true)
	var saved_settings = Progress.settings.duplicate(true)
	var saved_tutorial = Progress.tutorial_done
	var directory = "user://character3d_review_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	Progress.save_path = directory + "/style.json"
	Progress.storage = Store.new()
	Progress.save_enabled = true
	Progress.set_setting("characters_3d", false)
	Progress._ready()
	check(not Progress.settings.characters_3d and Progress.data == saved_data, "The new renderer preference persists without changing adventure progress")
	Progress.set_setting("characters_3d", true)
	Progress._ready()
	check(Progress.settings.characters_3d, "A cold reload restores the selected 3D presentation")
	var document = {"version": 1, "data": saved_data, "settings": {"painted_characters": true}, "tutorial_done": saved_tutorial}
	Progress.storage.write_text(Progress.save_path, JSON.stringify(document))
	Progress._ready()
	check(Progress.settings.characters_3d and Progress.settings.painted_characters and Progress.data == saved_data, "Legacy saves gain the 3D default while retaining their data and original-art choice")
	check(not Progress.set_setting("characters_3d", "false", false) and Progress.settings.characters_3d, "Malformed renderer values cannot become truthy presentation settings")
	Progress.save_enabled = false
	Progress.save_path = saved_path
	Progress.storage = saved_store
	Progress.data = saved_data
	Progress.settings = saved_settings
	Progress.tutorial_done = saved_tutorial

func review_studio():
	var studio = load(Adventures.STUDIO).instantiate()
	add_child(studio)
	await ticks(7)
	check(studio.mark.character3d.active and studio.bark.character3d.active, "The character studio exposes both full 3D models by default")
	studio.choose(5)
	await ticks(7)
	studio.toggle_pause()
	await ticks(3)
	var before = transform_snapshot(studio.mark.character3d.model)
	var age = studio.mark.age
	await ticks(10)
	check(studio.paused and studio.mark.age == age and transform_snapshot(studio.mark.character3d.model) == before, "Studio pause freezes actual facial and body geometry")
	studio.next_frame()
	check(studio.paused and studio.mark.age > age and transform_snapshot(studio.mark.character3d.model) != before, "Studio frame advance moves a real 3D performance while remaining paused")
	var stepped = transform_snapshot(studio.mark.character3d.model)
	age = studio.mark.age
	var basis: Basis = studio.mark.character3d.model.global_basis
	studio.mark.character3d.inspection_yaw += 0.8
	studio.mark.character3d.request_frame()
	await ticks(3)
	check(studio.mark.age == age and transform_snapshot(studio.mark.character3d.model) == stepped and not studio.mark.character3d.model.global_basis.is_equal_approx(basis), "Explicit 3D view inspection can orbit a held pose without advancing it")
	studio.toggle_points()
	await ticks(3)
	check(studio.mark.show_points and studio.bark.show_points and studio.mark.joint_position("head").is_finite(), "Studio joint inspection remains available for both 3D characters")
	await capture("studio_inspection")
	studio.toggle_points()
	studio.toggle_pause()
	studio.mark.character3d.inspection_yaw = 0.0
	studio.choose(6)
	await ticks(24)
	studio.toggle_pause()
	await native_pose_margins(studio.mark, "Mark's celebration")
	await native_pose_margins(studio.bark, "Bark's celebration")
	await capture("studio_celebration")
	studio.queue_free()
	await ticks(4)

func review_worlds():
	var game = load(Adventures.CLIMBS).instantiate()
	add_child(game)
	await ticks(5)
	for level in range(3):
		game.load_level(level)
		await ticks(8)
		check(game.player.sprite.character3d.active and game.campus.bark.character3d.active, "Climb " + str(level + 1) + " uses both volumetric characters in the actual game")
		var body = game.player.get_child(0)
		check(body is CollisionShape2D and body.shape is CapsuleShape2D and body.shape.radius == 14 and body.shape.height == 96, "Climb " + str(level + 1) + " keeps the original movement collision capsule")
		check(not game.player.ghost.visible, "Climb " + str(level + 1) + " does not crossfade a flat duplicate over the 3D actor")
		var before = Mega.runs.duplicate(true)
		game.place_player(Vector2(510, 650))
		game.notice_until = 0
		game.tutorial_hint_until = 0
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		game.player.sprite.frozen = true
		game.campus.bark.frozen = true
		game.update_hud()
		game.camera.force_update_scroll()
		await ticks(4)
		await capture(["library", "bedroom", "attic"][level])
		check(Mega.runs == before, "Climb " + str(level + 1) + " character review preserves discoveries and checkpoints")
		game.set_physics_process(true)
		game.player.set_physics_process(true)
		game.player.sprite.frozen = false
		game.campus.bark.frozen = false
	game.load_level(0)
	await ticks(8)
	var start = game.player.position
	game.jump()
	await ticks(20)
	game.jump()
	await ticks(3)
	check(game.player.jumps_used == 2 and game.player.position.y < start.y - 80 and game.player.sprite.character3d.active, "Actual 3D play still performs both immediate physical jumps")
	check(not game.player.ghost.visible and game.player.leaf_bursts.size() == 1, "The 3D spring keeps the anchored flourish without a flat ghost")
	game.pause_game()
	await ticks(3)
	var mark_pose = transform_snapshot(game.player.sprite.character3d.model)
	var bark_pose = transform_snapshot(game.campus.bark.character3d.model)
	await ticks(12)
	check(transform_snapshot(game.player.sprite.character3d.model) == mark_pose and transform_snapshot(game.campus.bark.character3d.model) == bark_pose, "Actual game pause freezes both 3D performances together")
	game.close()
	game.say(["Bark|A very bright idea!", "Mark|Let's give it a little more depth."])
	for page in range(2):
		await ticks(7)
		var portrait = game.dialogue_portrait
		var actor = portrait.actor
		var near: Vector2 = actor.joint_position("eye_near")
		var far: Vector2 = actor.joint_position("eye_far")
		var bounds = Rect2(Vector2.ZERO, portrait.size)
		check(actor.character3d.active and bounds.has_point(actor.transform * near) and bounds.has_point(actor.transform * far), ["Bark", "Mark"][page] + " dialogue portrait frames both actual 3D eyes inside its clipping bounds")
		await capture(["bark_portrait", "mark_portrait"][page])
		game.next_line()
	game.effects.stop()
	game.effects.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(4)
	var story = load(Adventures.STORY).instantiate()
	add_child(story)
	await ticks(5)
	story.start_campus()
	story.dismiss_dialogue()
	story.cancel_room_transition()
	story.set_physics_process(false)
	story.player.set_physics_process(false)
	story.player.reset_jumps()
	story.player.sprite.frozen = true
	story.campus.bark.frozen = true
	var original_progress = Progress.data.duplicate(true)
	for fixture in [["school", Vector2(1200, 610)], ["garden", Vector2(2740, 250)], ["workshop", Vector2(4490, 610)]]:
		story.player.position = fixture[1]
		story.player.velocity = Vector2.ZERO
		story.sync_room()
		var bark_x = story.player.position.x - 75.0
		story.campus.bark.position = Vector2(bark_x, story.campus.support_y(bark_x, story.player.position.y))
		story.camera.position = story.campus.camera_target(fixture[1].x, fixture[1].y)
		story.camera.force_update_scroll()
		story.toast_time = 0
		story.toast_panel.hide()
		story._hud_goal_pending = ""
		story._hud_goal_signature = story.mode + ":" + story.current_goal()
		story.update_hud()
		await ticks(5)
		check(story.player.sprite.character3d.active and story.campus.bark.character3d.active, "Original " + fixture[0] + " uses both 3D friends in the painted scene")
		var viewport = story.player.get_viewport_rect()
		check(viewport.has_point(story.player.get_global_transform_with_canvas().origin) and viewport.has_point(story.campus.bark.get_global_transform_with_canvas().origin), "Original " + fixture[0] + " stages both supporting-surface anchors inside the actual viewport")
		await capture(fixture[0])
	check(Progress.data == original_progress, "Character review preserves the original chapter's complete progression")
	story.sound_player.stop()
	story.sound_player.stream = null
	await story.soundscape.drain()
	story.queue_free()
	await ticks(4)

func run():
	get_tree().root.size = Vector2i(1280, 720)
	Progress.reset_game(false)
	Mega.reset(false)
	Progress.settings = Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.volume = 0
	Progress.settings.music = false
	Mega.prefs.calm = true
	Art.missing_assets.clear()
	check(not Progress.save_enabled and not Mega.enabled, "Character review isolates both persistent adventures before actor creation")
	check(Progress.SETTING_DEFAULTS.get("characters_3d") == true, "Character 2.0 is the default presentation for new and migrated preferences")
	await review_actor("mark")
	await review_actor("bark")
	Progress.settings.characters_3d = true
	Progress.settings.painted_characters = true
	await review_settings()
	await review_studio()
	await review_worlds()
	check(Art.missing_assets.is_empty(), "Character 2.0 does not request missing original artwork")
	check(not Progress.save_enabled and not Mega.enabled, "Character review finishes with both persistent save guards disabled")
	finish()
