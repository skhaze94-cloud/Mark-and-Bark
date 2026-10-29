extends Node
# Run: godot --headless --path . res://tests/graphics_review.tscn
# Native captures: godot --path . res://tests/graphics_review.tscn -- --screenshots
# Screenshot fixtures freeze simulation and never collect discoveries or checkpoints.

class SupportFixture extends Node2D:
	var floor_y = 190.0
	var last_query = Vector2.ZERO
	func support_y(x, feet_y):
		last_query = Vector2(x, feet_y)
		return floor_y

const SHADOW = preload("res://scripts/prop_shadow.gd")
const RISES = [
	[140,180,190,195,180,210,190,185],
	[145,195,205,210,220,200,220,205,200],
	[150,205,215,230,225,220,230,225,220,225,215]
]
const CENTERS = [
	[720,985,750,495,760,1025,770,510],
	[710,980,720,455,725,1000,740,470,745],
	[710,960,690,445,710,975,725,470,740,990,735]
]
const LEVEL_NAMES = ["library", "bedroom", "attic"]
const STORY_PLATFORMS = [
	Rect2(1990,550,180,20), Rect2(2225,490,175,20), Rect2(2470,430,190,20),
	Rect2(2730,430,190,20), Rect2(2980,430,190,20), Rect2(3220,490,180,20),
	Rect2(2060,290,190,20), Rect2(3200,190,210,20), Rect2(960,520,205,20),
	Rect2(1210,405,195,20), Rect2(1450,285,195,20), Rect2(2400,255,200,20),
	Rect2(2740,250,205,20), Rect2(3035,240,210,20), Rect2(4630,470,205,20),
	Rect2(4870,250,220,20), Rect2(5180,260,230,20)
]

var passed = 0
var failures = []
var screenshots = false
var finished = false
var game
var story

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
	await get_tree().process_frame

func _ready():
	# These guards precede every controller's _ready and every fixture mutation.
	Progress.save_enabled = false
	Mega.enabled = false
	var watchdog = Timer.new()
	watchdog.wait_time = 90.0
	watchdog.one_shot = true
	watchdog.timeout.connect(func():
		if not finished:
			check(false, "Graphics review completes within 90 seconds")
			finish()
	)
	add_child(watchdog)
	watchdog.start()
	call_deferred("run")

func finish():
	if finished:
		return
	finished = true
	print("GRAPHICS RESULT: ", passed, " passed; ", failures.size(), " failed")
	get_tree().quit(0 if failures.is_empty() else 1)

func capture(label):
	if not screenshots:
		return
	await ticks(2)
	await RenderingServer.frame_post_draw
	var image = get_tree().root.get_texture().get_image()
	check(image != null and not image.is_empty(), "Native viewport renders " + label)
	if image == null or image.is_empty():
		return
	var path = "res://test_output/graphics_" + label + ".png"
	check(image.save_png(path) == OK, "Native screenshot saved: " + label)
	print("GRAPHICS CAPTURE: ", path)

func visible_buttons(root):
	var buttons = []
	for child in root.get_children():
		if child is Button and child.is_visible_in_tree():
			buttons.append(child)
		buttons.append_array(visible_buttons(child))
	return buttons

func hud_fits_and_separates(hud, objective, counter):
	var viewport = Rect2(0, 0, 1280, 720).grow(1)
	var buttons = visible_buttons(hud)
	var valid = viewport.encloses(objective.get_global_rect()) and viewport.encloses(counter.get_global_rect())
	valid = valid and not objective.get_global_rect().intersects(counter.get_global_rect())
	for i in range(buttons.size()):
		var rect = buttons[i].get_global_rect()
		valid = valid and viewport.encloses(rect)
		valid = valid and not rect.intersects(objective.get_global_rect()) and not rect.intersects(counter.get_global_rect())
		for j in range(i + 1, buttons.size()):
			if rect.intersects(buttons[j].get_global_rect()):
				print("Overlapping HUD buttons: ", buttons[i].text, " / ", buttons[j].text)
				valid = false
	return valid

func has_collision(node):
	if node is CollisionObject2D or node is CollisionShape2D:
		return true
	for child in node.get_children():
		if has_collision(child):
			return true
	return false

func collider_rects(campus):
	var rects = []
	for child in campus.get_children():
		if not child is StaticBody2D:
			continue
		for shape in child.get_children():
			if shape is CollisionShape2D and shape.shape is RectangleShape2D:
				rects.append({
					"rect": Rect2(shape.position - shape.shape.size / 2.0, shape.shape.size),
					"one_way": shape.one_way_collision,
					"margin": shape.one_way_collision_margin,
					"layer": child.collision_layer,
					"mask": child.collision_mask
				})
	return rects

func collision_matches(campus, floor_rect, margin):
	var expected = [floor_rect]
	expected.append_array(campus.platforms)
	var actual = collider_rects(campus)
	if expected.size() != actual.size():
		return false
	for i in range(expected.size()):
		if actual[i].rect != expected[i] or actual[i].one_way != (i > 0):
			return false
		if actual[i].layer != 1 or actual[i].mask != 2:
			return false
		if i > 0 and actual[i].margin != margin:
			return false
	return true

func expected_climb(level):
	var rects = []
	var y = 650.0
	var count = RISES[level].size() * 3
	for n in range(count):
		y -= RISES[level][n % RISES[level].size()]
		var section = int(n / RISES[level].size())
		var x = CENTERS[level][n % CENTERS[level].size()] + [0, 35, -25][section]
		var width = 360.0 if n % 6 == 3 else float(280 - level * 30)
		if n % RISES[level].size() == 0:
			width = 320.0
		rects.append(Rect2(x - width / 2.0, y, width, 22))
	for leaf in [4, 12, 20]:
		var main_index = roundi(float(leaf) * (count - 1) / 23.0)
		var parent = rects[main_index]
		var next_x = rects[main_index + 1].get_center().x
		var direction = -1 if next_x >= parent.get_center().x else 1
		rects.append(Rect2(parent.get_center().x + 245 * direction - 90, parent.position.y - 70, 180, 22))
	return rects

func shadow_for(campus, actor):
	for child in campus.get_children():
		if child.get_script() == SHADOW and child.source == actor and child.follows:
			return child
	return null

func exercise_shadow(campus, actor, shadow, at, label):
	check(is_instance_valid(shadow), label + " has a dedicated contact shadow")
	if not is_instance_valid(shadow):
		return
	check(shadow.source == actor and shadow.follows and shadow.get_parent() == campus, label + " shadow follows the correct world actor")
	var matches = campus.get_children().filter(func(child): return child.get_script() == SHADOW and child.source == actor and child.follows)
	check(matches.size() == 1, label + " has exactly one world contact shadow")
	actor.position = at
	shadow._process(0.0)
	var ground = campus.support_y(at.x, at.y)
	check(shadow.position.is_equal_approx(Vector2(at.x, ground)) and is_zero_approx(shadow.lift), label + " shadow touches its support")
	var grounded_position = shadow.position
	actor.position.y -= 140.0
	shadow._process(0.0)
	check(shadow.position.is_equal_approx(grounded_position) and is_equal_approx(shadow.lift, 140.0), label + " airborne lift leaves its shadow on the same support")
	actor.hide()
	shadow._process(0.0)
	check(not shadow.visible, label + " shadow hides with its source")
	actor.show()
	actor.position = at
	shadow._process(0.0)
	check(shadow.visible and is_zero_approx(shadow.lift), label + " shadow returns cleanly on landing")

func transformed_shadow_fixture():
	var support = SupportFixture.new()
	support.position = Vector2(235, -80)
	support.scale = Vector2(1.4, 0.8)
	support.rotation = 0.17
	add_child(support)
	var branch = Node2D.new()
	branch.position = Vector2(41, 27)
	branch.scale = Vector2(0.7, 1.6)
	branch.rotation = -0.21
	support.add_child(branch)
	var source = Node2D.new()
	branch.add_child(source)
	var local_feet = Vector2(123, support.floor_y - 90)
	source.global_position = support.to_global(local_feet)
	var shadow = SHADOW.new()
	shadow.source = source
	shadow.follows = true
	support.add_child(shadow)
	shadow._process(0.0)
	check(support.last_query.is_equal_approx(local_feet), "Nested source passes support coordinates in its transformed owner's space")
	check(shadow.global_position.is_equal_approx(support.to_global(Vector2(local_feet.x, support.floor_y))) and is_equal_approx(shadow.lift, 90.0), "World contact follows nested source and transformed support without drift")
	shadow.follows = false
	shadow.anchor = Vector2(47, 82)
	source.position += Vector2(300, -120)
	shadow._process(0.0)
	check(shadow.position == shadow.anchor and is_zero_approx(shadow.lift), "Fixed prop shadow retains its anchor independently of source transforms")
	branch.hide()
	shadow._process(0.0)
	check(not shadow.visible, "A hidden source ancestor also hides its shadow")
	branch.show()
	source.queue_free()
	await ticks(3)
	check(not is_instance_valid(shadow), "Destroying a source removes its contact shadow without an orphan")
	support.queue_free()
	await ticks(2)

func alpha_metrics(image):
	var energy = 0.0
	var left = image.get_width()
	var right = -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha = image.get_pixel(x, y).a
			energy += alpha
			if alpha > 0.003:
				left = mini(left, x)
				right = maxi(right, x)
	return Vector2(energy, maxi(0, right - left + 1))

func native_shadow_fade(template, label):
	if not screenshots or not is_instance_valid(template):
		return
	var viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var support = SupportFixture.new()
	viewport.add_child(support)
	var source = Node2D.new()
	source.position = Vector2(128, support.floor_y)
	support.add_child(source)
	var shadow = SHADOW.new()
	shadow.source = source
	shadow.follows = true
	shadow.half_width = template.half_width
	shadow.softness = template.softness
	shadow.opacity = template.opacity
	support.add_child(shadow)
	await ticks(2)
	await RenderingServer.frame_post_draw
	var grounded = alpha_metrics(viewport.get_texture().get_image())
	source.position.y -= 140
	shadow._process(0.0)
	await ticks(2)
	await RenderingServer.frame_post_draw
	var airborne = alpha_metrics(viewport.get_texture().get_image())
	check(grounded.x > 0 and airborne.x > 0 and airborne.x < grounded.x * 0.9 and airborne.y < grounded.y, label + " native airborne shadow becomes lighter and smaller")
	viewport.queue_free()
	await ticks(2)

func climb_accessibility(level):
	game.set_physics_process(true)
	game.player.set_physics_process(true)
	game.place_player(Vector2(510, 647))
	Progress.settings.reduced_motion = true
	await ticks(5)
	var scenery = game.campus.scenery
	check(game.player.reduced_motion and game.campus.reduced_motion and scenery.reduced_motion and scenery.motes.reduced_motion and not scenery.motes.visible, LEVEL_NAMES[level] + " reduced motion reaches every new depth layer")
	check(is_zero_approx(game.player.sprite.rotation) and is_zero_approx(game.campus.bark.rotation), LEVEL_NAMES[level] + " reduced motion keeps character feet and silhouettes steady")
	Progress.settings.touch = true
	game.update_hud()
	await ticks(2)
	check(game.touch_root.visible and hud_fits_and_separates(game.hud, game.objective, game.counters), LEVEL_NAMES[level] + " touch HUD has no overlapping actions or objective text")
	Progress.settings.reduced_motion = false
	game.pause_game()
	await ticks(3)
	var mark_age = game.player.sprite.age
	var bark_age = game.campus.bark.age
	var bark_at = game.campus.bark.position
	var dust_age = scenery.motes.age
	var mark_shadow = shadow_for(game.campus, game.player)
	var shadow_at = mark_shadow.position if is_instance_valid(mark_shadow) else Vector2.ZERO
	await ticks(10)
	check(game.player.sprite.age == mark_age and game.campus.bark.age == bark_age and game.campus.bark.position == bark_at and scenery.motes.age == dust_age, LEVEL_NAMES[level] + " pause freezes both friends and atmospheric depth")
	check(is_instance_valid(mark_shadow) and mark_shadow.position == shadow_at, LEVEL_NAMES[level] + " pause keeps contact shadows fixed")
	game.close()
	await ticks(4)
	check(game.player.sprite.age > mark_age and game.campus.bark.age > bark_age and scenery.motes.age > dust_age, LEVEL_NAMES[level] + " graphics resume after pause")
	Progress.settings.touch = false
	game.update_hud()

func climb_captures(level):
	if not screenshots:
		return
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.sprite.frozen = true
	game.campus.bark.frozen = true
	var before = Mega.runs.duplicate(true)
	var count = game.campus.RISES[level].size()
	var child_count = game.campus.scenery.get_child_count()
	for fixture in [["floor", -1], ["mid", int(count / 2) - 1], ["summit", count - 1]]:
		var at = Vector2(510, 650) if fixture[1] < 0 else Vector2(game.campus.platforms[fixture[1]].get_center().x, game.campus.platforms[fixture[1]].position.y)
		game.place_player(at)
		game.last_shelf = fixture[1] + 1
		game.player.sprite.frozen = true
		game.campus.bark.frozen = true
		game.campus.bark.position.y = game.campus.support_y(game.campus.bark.position.x, at.y)
		game.notice.hide()
		game.notice_back.hide()
		game.update_hud()
		print("GRAPHICS FIXTURE: ", LEVEL_NAMES[level], "/", fixture[0], " feet=", at, " camera=", game.camera.position)
		await capture(LEVEL_NAMES[level] + "_" + fixture[0])
		check(game.campus.scenery.get_child_count() == child_count, LEVEL_NAMES[level] + " scenery stays bounded at " + fixture[0])
		if fixture[0] == "floor":
			game.player.position.y -= 140
			await capture(LEVEL_NAMES[level] + "_airborne")
			game.player.position = at
	Progress.settings.touch = true
	game.update_hud()
	await capture(LEVEL_NAMES[level] + "_touch")
	Progress.settings.touch = false
	check(Mega.runs == before, LEVEL_NAMES[level] + " screenshots preserve every leaf, quest and checkpoint")
	game.place_player(Vector2(510, 647))
	game.player.sprite.frozen = false
	game.campus.bark.frozen = false
	game.player.set_physics_process(true)
	game.set_physics_process(true)

func review_story():
	story = load(Adventures.STORY).instantiate()
	add_child(story)
	await ticks(3)
	story.start_campus()
	story.dismiss_dialogue()
	story.player.position = Vector2(1200, 610)
	story.player.velocity = Vector2.ZERO
	story.sync_room()
	story.set_physics_process(false)
	story.player.set_physics_process(false)
	await ticks(3)
	check(not story.player.contact_shadow_enabled, "Original chapter uses one dedicated Mark shadow")
	check(story.campus.platforms == STORY_PLATFORMS and collision_matches(story.campus, Rect2(0,610,5600,120), 8), "Original chapter keeps all 17 routes and their exact collision tops")
	check(story.campus.backgrounds.size() == 3 and story.campus.fun_ledges.size() == 11, "Original school, garden and workshop retain their painted traversal")
	var mark_shadow = story.campus.get_node_or_null("MarkContactShadow")
	var bark_shadow = shadow_for(story.campus, story.campus.bark)
	exercise_shadow(story.campus, story.player, mark_shadow, Vector2(600, 610), "Story Mark")
	exercise_shadow(story.campus, story.campus.bark, bark_shadow, Vector2(510, 610), "Story Bark")
	check(not story.player.sprite.mesh.visible and not story.campus.bark.mesh.visible, "Original chapter retains the complete supplied character paintings")
	var origins = []
	for piece in story.campus.scenery.planes:
		origins.append(piece.sprite.position)
	story.camera.position.x += 250
	await ticks(4)
	var anchored = true
	for i in range(origins.size()):
		anchored = anchored and story.campus.scenery.planes[i].sprite.position == origins[i]
	check(anchored and not has_collision(story.campus.scenery) and not has_collision(story.campus.depth), "Original depth furniture stays anchored and adds no collision")
	story.player.set_physics_process(true)
	story.set_physics_process(true)
	Progress.settings.reduced_motion = true
	story.apply_settings()
	await ticks(5)
	var still = true
	for piece in story.campus.scenery.planes:
		still = still and is_zero_approx(piece.sprite.rotation)
	check(still and story.campus.depth.reduced_motion and story.campus.foreground.reduced_motion and story.campus.scenery.reduced_motion, "Original reduced motion reaches foreground, light and anchored foliage")
	Progress.settings.touch = true
	story.apply_settings()
	story.update_hud()
	await ticks(2)
	check(story.touch_root.visible and hud_fits_and_separates(story.hud, story.objective, story.counter), "Original touch HUD keeps all actions and objective text separate")
	Progress.settings.reduced_motion = false
	story.show_pause()
	await ticks(3)
	var mark_age = story.player.sprite.age
	var bark_age = story.campus.bark.age
	var bark_at = story.campus.bark.position
	var depth_time = story.campus.depth.time
	var foreground_time = story.campus.foreground.time
	var scenery_time = story.campus.scenery.time
	await ticks(10)
	check(story.player.sprite.age == mark_age and story.campus.bark.age == bark_age and story.campus.bark.position == bark_at, "Original pause freezes both actors and companion placement")
	check(story.campus.depth.time == depth_time and story.campus.foreground.time == foreground_time and story.campus.scenery.time == scenery_time, "Original pause freezes ambient depth and foliage")
	story.close_modal()
	await ticks(4)
	check(story.player.sprite.age > mark_age and story.campus.bark.age > bark_age, "Original character animation resumes after pause")
	if screenshots:
		story.set_physics_process(false)
		story.player.set_physics_process(false)
		story.player.sprite.frozen = true
		story.campus.bark.frozen = true
		var before = Progress.data.duplicate(true)
		for fixture in [["school", Vector2(1200,610)], ["garden", Vector2(2740,250)], ["workshop", Vector2(4490,610)]]:
			story.player.position = fixture[1]
			story.player.velocity = Vector2.ZERO
			story.sync_room()
			story.campus.bark.position.y = story.campus.support_y(story.campus.bark.position.x, fixture[1].y)
			story.camera.position = story.campus.camera_target(fixture[1].x, fixture[1].y)
			story.toast_panel.hide()
			story.update_hud()
			print("GRAPHICS FIXTURE: story/", fixture[0], " feet=", fixture[1], " camera=", story.camera.position)
			await capture("story_" + fixture[0])
		check(Progress.data == before, "Original screenshots preserve story progression")
	story.sound_player.stop()
	story.sound_player.stream = null
	await story.soundscape.drain()
	story.queue_free()
	await ticks(3)
	Progress.settings.touch = false

func run():
	get_tree().root.size = Vector2i(1280, 720)
	screenshots = "--screenshots" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	if "--screenshots" in OS.get_cmdline_user_args() and not screenshots:
		print("GRAPHICS SKIP: native screenshots require a display; headless assertions continue")
	if screenshots:
		check(DirAccess.make_dir_recursive_absolute("res://test_output") == OK, "Screenshot output directory is writable")
	Progress.reset_game(false)
	Mega.reset(false)
	Progress.settings = Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.volume = 0.0
	Progress.settings.music = false
	Mega.prefs.calm = true
	Art.missing_assets.clear()
	check(not Progress.save_enabled and not Mega.enabled, "Review disables both save systems before constructing game scenes")
	var assets_present = true
	for id in Art.index:
		assets_present = assets_present and ResourceLoader.exists(Art.index[id].path)
		var texture = Art.tex(id)
		assets_present = assets_present and texture != null and texture.get_width() > 0
	for path in ["res://shaders/mega_finish.gdshader", "res://shaders/storybook_finish.gdshader", "res://shaders/character_face.gdshader"]:
		assets_present = assets_present and ResourceLoader.exists(path) and load(path) != null
	check(assets_present and Art.missing_assets.is_empty(), "All registered paintings and native finish shaders resolve")
	await transformed_shadow_fixture()
	var retained_story = Progress.data.duplicate(true)
	game = load(Adventures.CLIMBS).instantiate()
	add_child(game)
	await ticks(3)
	var total_shelves = 0
	var total_leaves = 0
	for level in range(3):
		game.load_level(level)
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		await ticks(4)
		var campus = game.campus
		var expected = expected_climb(level)
		var main_count = RISES[level].size() * 3
		total_shelves += main_count
		var leaves = campus.pickups.filter(func(p): return p.kind == "leaf")
		total_leaves += leaves.size()
		check(campus.platforms == expected and campus.RISES[level].size() == main_count and campus.branches.size() == 3, LEVEL_NAMES[level] + " retains every main shelf and all three exact nook positions")
		check(collision_matches(campus, Rect2(0,650,1600,150), 10), LEVEL_NAMES[level] + " painted ledges preserve one-way collision geometry")
		var leaf_ids = leaves.map(func(p): return p.id)
		leaf_ids.sort()
		check(leaf_ids == range(24) and campus.pickups.size() == 25, LEVEL_NAMES[level] + " retains all 24 unique leaves and Bark's token")
		check(not has_collision(campus.scenery), LEVEL_NAMES[level] + " depth painting creates no invisible collision")
		check(not game.player.contact_shadow_enabled, LEVEL_NAMES[level] + " disables the old duplicate Mark shadow")
		var prefix = "LibraryContactShadow" if level == 0 else "WorldContactShadow"
		var mark_shadow = campus.get_node_or_null(prefix + "Mark")
		var bark_shadow = campus.get_node_or_null(prefix + "Bark")
		var at = Vector2(campus.platforms[0].get_center().x, campus.platforms[0].position.y)
		exercise_shadow(campus, game.player, mark_shadow, at, LEVEL_NAMES[level] + " Mark")
		exercise_shadow(campus, campus.bark, bark_shadow, at + Vector2(-35,0), LEVEL_NAMES[level] + " Bark")
		check(not game.player.sprite.mesh.visible and not campus.bark.mesh.visible, LEVEL_NAMES[level] + " retains the supplied painted characters")
		var scenery_children = campus.scenery.get_child_count()
		var floor_bay = campus.scenery.visible_bay
		game.camera.position.y = campus.top - 120
		await ticks(3)
		check(campus.scenery.visible_bay != floor_bay and campus.scenery.get_child_count() == scenery_children and not has_collision(campus.scenery), LEVEL_NAMES[level] + " camera culls world bays without adding geometry nodes")
		await native_shadow_fade(mark_shadow, LEVEL_NAMES[level])
		await climb_accessibility(level)
		await climb_captures(level)
	check(total_shelves == 84 and total_leaves == 72, "The complete campaign preserves 84 main platforms and 72 leaves")
	check(Progress.data == retained_story, "Reviewing all three climbs preserves the original chapter")
	game.effects.stop()
	game.effects.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(3)
	var retained_climbs = Mega.runs.duplicate(true)
	await review_story()
	check(Mega.runs == retained_climbs, "Reviewing the original chapter preserves all three climb runs")
	check(Art.missing_assets.is_empty(), "Graphics, shadows and captures request no missing artwork")
	check(not Progress.save_enabled and not Mega.enabled, "Both persistent save guards remain disabled")
	finish()
