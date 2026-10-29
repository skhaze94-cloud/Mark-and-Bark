extends Node
# Exercise the decoration through the same pause/settings paths as players.
# Existing graphics_review owns route, character, shadow and native capture checks.
const WHIMSY = preload("res://scripts/whimsy_layer.gd")
const LEVEL_NAMES = ["Library", "Bedroom", "Attic"]

var passed = 0
var failures = []
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
	await get_tree().process_frame

func _ready():
	Progress.save_enabled = false
	Mega.enabled = false
	var watchdog = Timer.new()
	watchdog.wait_time = 90.0
	watchdog.one_shot = true
	watchdog.timeout.connect(func():
		if not finished:
			check(false, "Whimsy review completes within 90 seconds")
			finish()
	)
	add_child(watchdog)
	watchdog.start()
	call_deferred("run")

func finish():
	if finished:
		return
	finished = true
	print("WHIMSY RESULT: ", passed, " passed; ", failures.size(), " failed")
	get_tree().quit(0 if failures.is_empty() else 1)

func find_layers(node):
	var layers = []
	if node.get_script() == WHIMSY:
		layers.append(node)
	for child in node.get_children():
		layers.append_array(find_layers(child))
	return layers

func has_collision(node):
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		return true
	for child in node.get_children():
		if has_collision(child):
			return true
	return false

func node_count(node):
	var result = 1
	for child in node.get_children():
		result += node_count(child)
	return result

func anchors(layer):
	var result = {}
	for decoration in layer.visible_decorations():
		result[decoration.id] = decoration.anchor
	return result

func valid_decorations(layer):
	var entries = layer.visible_decorations()
	if entries.is_empty() or entries.size() > WHIMSY.MAX_DECORATIONS:
		return false
	var ids = {}
	for entry in entries:
		for key in ["id", "anchor", "kind", "phase", "scale", "theme"]:
			if not entry.has(key):
				return false
		if typeof(entry.id) != TYPE_STRING or ids.has(entry.id):
			return false
		if typeof(entry.anchor) != TYPE_VECTOR2 or not entry.anchor.is_finite():
			return false
		if not is_finite(float(entry.phase)) or not is_finite(float(entry.scale)) or float(entry.scale) <= 0:
			return false
		ids[entry.id] = true
	return true

func inspect_layer(world, layer, controller, context, label):
	var layers = find_layers(world)
	check(layers.size() == 1 and layers[0] == layer, label + " installs exactly one shared whimsy layer")
	if not is_instance_valid(layer):
		return false
	check(layer.context == context and layer.controller == controller, label + " decoration follows the correct scene context")
	check(not has_collision(layer), label + " decoration creates no gameplay collision")
	var rect = layer.frame_rect()
	check(rect.position.is_finite() and rect.size.x > 0 and rect.size.y > 0, label + " culling uses a valid world viewport")
	check(valid_decorations(layer), label + " visible ornaments have unique deterministic identities and bounded valid data")
	return true

func inspect_camera_travel(layer, camera, offset, label):
	var origin = camera.position
	var before = anchors(layer)
	var count = node_count(layer)
	camera.position += offset
	camera.force_update_scroll()
	await ticks(3)
	var during = anchors(layer)
	var common = 0
	var anchored = true
	for id in before:
		if during.has(id):
			common += 1
			anchored = anchored and during[id] == before[id]
	check(common > 0 and anchored, label + " camera movement leaves shared ornaments anchored in world space")
	check(valid_decorations(layer) and node_count(layer) == count, label + " camera culling keeps ornament work and scene nodes bounded")
	camera.position = origin
	camera.force_update_scroll()
	await ticks(3)
	check(anchors(layer) == before, label + " revisiting a view restores the same ornament positions")
	# Repeated offscreen travel must not accumulate particles or scene children.
	for i in range(12):
		camera.position = origin + offset * float(i + 1)
		camera.force_update_scroll()
		layer.visible_decorations()
		if layer.visible_decorations().size() > WHIMSY.MAX_DECORATIONS:
			anchored = false
	camera.position = origin
	camera.force_update_scroll()
	await ticks(3)
	check(anchored and node_count(layer) == count, label + " repeated exploration cannot accumulate decoration nodes or unbounded work")

func inspect_pause(layer, open_pause: Callable, close_pause: Callable, label):
	Progress.settings.reduced_motion = false
	await ticks(3)
	var before = layer.time
	await ticks(5)
	check(layer.time > before, label + " environmental motion advances during play")
	open_pause.call()
	await ticks(3)
	var paused_at = layer.time
	await ticks(6)
	check(layer.paused and layer.time == paused_at, label + " pause freezes environmental motion")
	Progress.settings.reduced_motion = true
	await ticks(3)
	check(layer.reduced_motion and layer.paused and layer.time == paused_at, label + " reduced motion applies immediately inside paused settings")
	check(valid_decorations(layer) and layer.visible, label + " reduced motion preserves the static storybook ornaments")
	close_pause.call()
	await ticks(6)
	check(not layer.paused and layer.time == paused_at, label + " reduced motion remains still when play resumes")
	Progress.settings.reduced_motion = false
	await ticks(5)
	check(not layer.reduced_motion and layer.time > paused_at, label + " environmental motion resumes after reduced motion is disabled")

func review_climbs():
	var game = load(Adventures.CLIMBS).instantiate()
	add_child(game)
	await ticks(3)
	for level in range(3):
		game.load_level(level)
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		await ticks(4)
		var layer = game.campus.whimsy
		var label = LEVEL_NAMES[level]
		if not inspect_layer(game.campus, layer, game, "climb", label):
			continue
		check(layer.level == level, label + " selects its own visual theme")
		var saved = Mega.runs.duplicate(true)
		var platforms = game.campus.platforms.duplicate()
		var player_at = game.player.position
		await inspect_camera_travel(layer, game.camera, Vector2(15, -120), label)
		await inspect_pause(layer, game.pause_game, game.close, label)
		check(game.campus.platforms == platforms and game.player.position == player_at and Mega.runs == saved,
			label + " decoration and accessibility settings leave routes, actors and discoveries untouched")
	game.effects.stop()
	game.effects.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(3)

func review_story():
	var game = load(Adventures.STORY).instantiate()
	add_child(game)
	await ticks(3)
	game.start_campus()
	game.dismiss_dialogue()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector2(1200, 610)
	game.camera.position = game.campus.camera_target(1200, 610)
	game.camera.force_update_scroll()
	await ticks(4)
	var layer = game.campus.whimsy
	if inspect_layer(game.campus, layer, game, "story", "Original adventure"):
		var saved = Progress.data.duplicate(true)
		var platforms = game.campus.platforms.duplicate()
		var player_at = game.player.position
		for fixture in [["School", Vector2(1200, 610)], ["Garden", Vector2(2740, 250)], ["Workshop", Vector2(4490, 610)]]:
			game.camera.position = game.campus.camera_target(fixture[1].x, fixture[1].y)
			game.camera.force_update_scroll()
			await ticks(3)
			check(valid_decorations(layer), fixture[0] + " has bounded themed storybook detail")
			await inspect_camera_travel(layer, game.camera, Vector2(110, 0), fixture[0])
		await inspect_pause(layer, game.show_pause, game.close_modal, "Original adventure")
		check(game.campus.platforms == platforms and game.player.position == player_at and Progress.data == saved,
			"Original decoration and accessibility settings preserve story routes, actors and progress")
	game.sound_player.stop()
	game.sound_player.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(3)

func review_menu():
	var menu = load(Adventures.HOME).instantiate()
	add_child(menu)
	await ticks(4)
	var layer = menu.whimsy
	if inspect_layer(menu, layer, menu, "menu", "Opening menu"):
		var mark_at = menu.mark.position
		var bark_at = menu.bark.position
		var saved_story = Progress.data.duplicate(true)
		var saved_climbs = Mega.runs.duplicate(true)
		await inspect_pause(layer, menu.show_settings, menu.close_settings, "Opening menu")
		check(menu.mark.position == mark_at and menu.bark.position == bark_at and Progress.data == saved_story and Mega.runs == saved_climbs,
			"Opening menu ornaments preserve both original character placements and adventures")
	await menu.drain_audio()
	menu.queue_free()
	await ticks(3)

func run():
	get_tree().root.size = Vector2i(1280, 720)
	Progress.reset_game(false)
	Mega.reset(false)
	Progress.settings = Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.volume = 0.0
	Progress.settings.music = false
	Mega.prefs.calm = true
	Art.missing_assets.clear()
	check(not Progress.save_enabled and not Mega.enabled, "Whimsy review isolates both persistent adventures")
	await review_climbs()
	await review_story()
	await review_menu()
	check(Art.missing_assets.is_empty(), "Whimsy update requests no missing artwork")
	check(not Progress.save_enabled and not Mega.enabled, "Whimsy review keeps both persistent save guards disabled")
	finish()
