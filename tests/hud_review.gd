extends Node
## Real controller/input checks for the quiet HUD. Saves are disabled before scenes load.
const HUD = preload("res://scripts/whimsy_hud.gd")
const OLD_DESKTOP_AREA = 159200.0 # 3.5's already-compact library panels/buttons.
const OLD_TOUCH_AREA = 209000.0 # 3.5 library touch header, tools and action panels.
var passed = 0
var failures = []
var finished = false
var screenshots = false

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
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://test_output")
	var watchdog = Timer.new()
	watchdog.wait_time = 120
	watchdog.one_shot = true
	watchdog.timeout.connect(func():
		if not finished:
			check(false, "HUD review completes within 120 seconds")
			finish()
	)
	add_child(watchdog)
	watchdog.start()
	call_deferred("run")

func finish():
	if finished:
		return
	finished = true
	print("HUD RESULT: ", passed, " passed; ", failures.size(), " failed")
	get_tree().quit(0 if failures.is_empty() else 1)

func key(code):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	get_tree().root.push_input(event, true)
	await ticks(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	get_tree().root.push_input(event, true)
	await ticks(2)

func click(control):
	if not is_instance_valid(control):
		return
	for pressed in [true, false]:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		get_tree().root.push_input(event, true)
		await ticks(2)

func touch(index, action, pressed, hud):
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = hud.touch_rect(action).get_center()
	event.pressed = pressed
	get_tree().root.push_input(event, true)
	await ticks(2)

func buttons(root):
	var result = []
	for child in root.get_children():
		if child is Button and child.is_visible_in_tree():
			result.append(child)
		result.append_array(buttons(child))
	return result

func find_button(root, title):
	for button in buttons(root):
		if button.text == title:
			return button
	return null

func labels(root):
	var result = ""
	for child in root.get_children():
		if child is Label and child.is_visible_in_tree():
			result += child.text + "\n"
		result += labels(child)
	return result

func fits(rectangles, viewport):
	for i in range(rectangles.size()):
		if not viewport.grow(1).encloses(rectangles[i]) or rectangles[i].size.x <= 0 or rectangles[i].size.y <= 0:
			return false
		for j in range(i + 1, rectangles.size()):
			if rectangles[i].intersects(rectangles[j]):
				return false
	return true

func hud_layout(game, label, found, total, touch_mode):
	var hud = game.whimsy_hud
	check(hud.get_script() == HUD and hud.controller == game, label + " uses the same small HUD and correct controller")
	check(hud.score == found and hud.total == total and hud.score_button.text == str(found) + " / " + str(total), label + " leaf capsule reports the actual adventure score")
	check(hud.persistent_rects().size() == 3 and hud.idle_area() <= OLD_DESKTOP_AREA * .10, label + " has only three small regions and at least 90% less idle panel area")
	check(fits(hud.occupied_rects(), Rect2(Vector2.ZERO, hud.get_viewport_rect().size)), label + " active HUD regions fit the viewport without overlap")
	var center_clear = true
	for rect in hud.occupied_rects():
		center_clear = center_clear and not rect.intersects(Rect2(250, 140, 780, 420))
	check(center_clear, label + " leaves the central adventure view open")
	check(buttons(game.hud).all(func(button): return button.focus_mode == Control.FOCUS_NONE), label + " HUD buttons cannot steal keyboard jump focus")
	if touch_mode:
		var area = 0.0
		for rect in hud.occupied_rects():
			area += rect.get_area()
		check(hud.touch_root.visible and hud.touch_buttons.left.visible and hud.touch_buttons.right.visible and hud.touch_buttons.jump.visible, label + " retains usable move and jump controls")
		check(area <= OLD_TOUCH_AREA * .20, label + " cuts touch overlay area by at least 80%")
	else:
		check(not hud.touch_root.visible, label + " keeps touch controls off the keyboard view")

func capture(name):
	if not screenshots:
		return
	await ticks(2)
	await RenderingServer.frame_post_draw
	var image = get_tree().root.get_texture().get_image()
	check(image != null and not image.is_empty(), "Native viewport renders " + name)
	if image != null and not image.is_empty():
		check(image.save_png("res://test_output/hud_" + name + ".png") == OK, "HUD screenshot saves " + name)

func menu_tools(game, story):
	var hud = game.whimsy_hud
	var name = "Original adventure" if story else "Climbs"
	await click(hud.pause_button)
	check(game.busy and hud.paused and not hud.touch_root.visible, name + " icon pause freezes play and hides touch controls")
	var menu = game.modal if story else game.panel
	for title in ["Notebook", "Bark's hint", "Restart checkpoint" if story else "Return to checkpoint"]:
		check(is_instance_valid(find_button(menu, title)), name + " keeps " + title + " in the pause menu")
	if story:
		var goal = menu.find_child("PauseObjective", true, false)
		check(is_instance_valid(goal) and goal.get_parent().get_global_rect().encloses(goal.get_global_rect()) and goal.get_line_count() >= 2 and goal.get_line_count() <= goal.get_visible_line_count(), "The paused story objective wraps completely within its paper sidecard")
	await capture("story_pause" if story else "climb_pause")
	await click(find_button(menu, "Notebook"))
	check(game.busy and "NOTEBOOK" in labels(game), name + " pause Notebook opens the full adventure detail")
	await key(KEY_ESCAPE)
	if game.busy:
		await click(find_button(game.modal if story else game.panel, "Continue"))
	await click(hud.pause_button)
	await click(find_button(game.modal if story else game.panel, "Bark's hint"))
	check(game.busy and is_instance_valid(game.dialogue_text if story else game.dialogue_label), name + " pause hint reaches Bark's real dialogue")
	await key(KEY_ESCAPE)
	if game.busy:
		await click(find_button(game.modal if story else game.panel, "Continue"))
	await click(hud.score_button)
	check(game.busy and "NOTEBOOK" in labels(game), name + " leaf capsule also opens the notebook")
	await key(KEY_ESCAPE)
	if game.busy:
		await click(find_button(game.modal if story else game.panel, "Continue"))
	await key(KEY_N)
	check(game.busy and "NOTEBOOK" in labels(game), name + " keyboard Notebook shortcut remains reachable")
	await key(KEY_ESCAPE)
	if game.busy:
		await click(find_button(game.modal if story else game.panel, "Continue"))
	var saved = Progress.data.duplicate(true) if story else Mega.runs.duplicate(true)
	await click(hud.pause_button)
	await click(find_button(game.modal if story else game.panel, "Restart checkpoint" if story else "Return to checkpoint"))
	check(not game.busy and (Progress.data == saved if story else Mega.runs == saved), name + " pause checkpoint preserves every quest and discovery")

func energy_input(game, story):
	var hud = game.whimsy_hud
	var name = "Original adventure" if story else "Climbs"
	await ticks(12)
	check(game.player.is_on_floor() and hud.energy == 2, name + " grounded spring meter has two real charges")
	await key(KEY_SPACE)
	check(game.player.jumps_used == 1 and hud.energy == 1 and game.player.velocity.y < 0, name + " keyboard jump consumes one displayed spring charge")
	await ticks(16)
	await key(KEY_SPACE)
	check(game.player.jumps_used == 2 and hud.energy == 0 and game.player.velocity.y < 0, name + " Bark spring consumes the second real displayed charge")
	await capture("story_spring" if story else "climb_spring")
	await key(KEY_SPACE)
	check(game.player.jumps_used == 2 and hud.energy == 0, name + " empty spring meter cannot grant a third jump")
	await ticks(110)
	check(game.player.is_on_floor() and hud.energy == 2, name + " landing replenishes the live spring meter")
	Progress.settings.touch = true
	game.update_hud()
	await ticks(3)
	var before = game.player.position.x
	await touch(21, "right", true, hud)
	await touch(22, "jump", true, hud)
	await touch(22, "jump", false, hud)
	await ticks(10)
	check(game.player.position.x > before + 20 and game.player.jumps_used == 1, name + " two compact touch controls can move and jump together")
	await touch(21, "right", false, hud)
	await ticks(10)
	await touch(23, "jump", true, hud)
	await touch(23, "jump", false, hud)
	check(game.player.jumps_used == 2 and hud.energy == 0, name + " compact touch Jump can trigger the second spring")
	await key(KEY_ESCAPE)
	check(game.busy and (game.touch_fingers.is_empty() and not game.touches.right if story else game.fingers.is_empty()), name + " pause releases held touch input")
	await key(KEY_ESCAPE)
	Progress.settings.touch = false
	game.update_hud()

func review_climbs():
	var game = load(Adventures.CLIMBS).instantiate()
	add_child(game)
	await ticks(4)
	for level in range(3):
		Progress.settings.touch = false
		game.touch_mode = false
		game.load_level(level)
		await ticks(10)
		game.tutorial_hint_until = 0
		game.notice_until = 0
		game.update_hud()
		await ticks(2)
		var name = ["library", "bedroom", "attic"][level]
		hud_layout(game, name + " keyboard", Mega.runs[level].leaves.size(), 24, false)
		check(not game.library_header.is_visible_in_tree() and not game.route_label.is_visible_in_tree(), name + " old quest and shelf panels remain hidden")
		await capture(name + "_keyboard")
		Progress.settings.touch = true
		game.update_hud()
		await ticks(2)
		hud_layout(game, name + " touch", Mega.runs[level].leaves.size(), 24, true)
		check(not game.whimsy_hud.touch_buttons.use.is_visible_in_tree(), name + " hides Use when no usable object is nearby")
		await capture(name + "_touch")
		var quest_shelf = game.campus.platforms[game.campus.RISES[level].size() - 2]
		game.place_player(Vector2(quest_shelf.get_center().x, quest_shelf.position.y - 3))
		await ticks(12)
		# A just-earned portrait/checkpoint notice takes its turn before the prompt.
		# Wait out the real card instead of masking a timing-sensitive user state.
		for wait_frame in range(600):
			if not game.notice.visible:
				break
			await ticks(1)
		check(game.whimsy_hud.touch_buttons.use.is_visible_in_tree() and game.context_back.is_visible_in_tree(), name + " reveals Use and one short prompt at the real quest item")
		game.retry()
		game.notice_until = 0
		await ticks(8)
	game.load_level(0)
	await ticks(10)
	Progress.settings.touch = false
	game.touch_mode = false
	var leaf = game.campus.pickups.filter(func(item): return item.kind == "leaf")[0]
	var before_score = Mega.runs[0].leaves.size()
	game.player.position = leaf.pos + Vector2(0, 35)
	await ticks(3)
	check(Mega.runs[0].leaves.size() == before_score + 1 and game.whimsy_hud.score == before_score + 1, "Walking into a real leaf updates the small score capsule")
	check(game.whimsy_hud.score_pulse > 0, "A new leaf gives brief whimsical score feedback")
	await key(KEY_ESCAPE)
	var pulse = game.whimsy_hud.score_pulse
	await ticks(8)
	check(game.whimsy_hud.paused and game.whimsy_hud.score_pulse == pulse, "Pause freezes score feedback without dropping the count")
	Progress.settings.reduced_motion = true
	await ticks(3)
	check(game.whimsy_hud.reduced_motion and game.whimsy_hud.score_pulse == 0, "Reduced motion cancels the flourish immediately while paused")
	await key(KEY_ESCAPE)
	Progress.settings.reduced_motion = false
	game.retry()
	await energy_input(game, false)
	game.retry()
	await ticks(8)
	await menu_tools(game, false)
	game.effects.stop()
	game.effects.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(3)

func review_story():
	var game = load(Adventures.STORY).instantiate()
	add_child(game)
	await ticks(4)
	game.start_campus()
	game.dismiss_dialogue()
	game.player.position = Vector2(600, 605)
	await ticks(10)
	Progress.collect_leaf("leaf_1")
	await ticks(3)
	check(game.whimsy_hud.score == Progress.data.leaves.size() and game.whimsy_hud.total == 6, "Original discoveries update the same small score design")
	game.toast_time = 0
	game.on_player_jump(true)
	var quiet_spring = game.toast_time == 0
	game.show_notebook()
	await ticks(2)
	var notebook_text = labels(game)
	check(quiet_spring and game.BARK_NOTEBOOK_QUIPS.any(func(quip): return quip in notebook_text), "A story spring stays quiet while Bark's playful quips remain readable in the notebook")
	game.close_modal()
	await energy_input(game, true)
	game.restart_checkpoint()
	await ticks(8)
	await menu_tools(game, true)
	# Fixture jumps are direct staging, never a room-crossing gameplay event.
	# Clear any transition before freezing simulation so it cannot mask the view.
	game.cancel_room_transition()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	# Settle the actor presentation before recording a still frame; otherwise a
	# legitimate 65ms pose crossfade can be frozen as two translucent Marks.
	game.player.reset_jumps()
	game.campus.bark.reset_motion()
	game.campus.bark.texture = Art.tex("bark_actions_idle")
	game.campus.bark.rotation = 0
	var mark_was_frozen = game.player.sprite.frozen
	var bark_was_frozen = game.campus.bark.frozen
	game.player.sprite.frozen = true
	game.campus.bark.frozen = true
	var saved = Progress.data.duplicate(true)
	for fixture in [["school", Vector2(1200, 610)], ["garden", Vector2(2740, 250)], ["workshop", Vector2(4490, 610)]]:
		game.player.position = fixture[1]
		game.player.velocity = Vector2.ZERO
		# camera_target clamps against the active room, so synchronize it first.
		game.sync_room()
		var bark_x = game.player.position.x - 75.0
		game.campus.bark.position = Vector2(bark_x, game.campus.support_y(bark_x, game.player.position.y))
		game.camera.position = game.campus.camera_target(fixture[1].x, fixture[1].y)
		game.camera.force_update_scroll()
		game.toast_time = 0
		game.toast_panel.hide()
		game.toast_label.hide()
		game._hud_goal_pending = ""
		game._hud_goal_signature = game.mode + ":" + game.current_goal()
		for touch_mode in [false, true]:
			Progress.settings.touch = touch_mode
			game.input_touch = false
			game.update_hud()
			await ticks(2)
			var viewport = game.player.get_viewport_rect()
			var mark_feet = game.player.get_global_transform_with_canvas().origin
			var bark_feet = game.campus.bark.get_global_transform_with_canvas().origin
			var correct_room = game.campus.room == game.campus.room_for(fixture[1].x)
			check(correct_room and game.room_transition.is_empty() and not game.player.ghost.visible and game.player.sprite.modulate.a == 1 and viewport.encloses(Rect2(mark_feet - Vector2(32, 155), Vector2(64, 155))) and viewport.encloses(Rect2(bark_feet - Vector2(40, 110), Vector2(80, 110))), fixture[0] + (" touch" if touch_mode else " keyboard") + " stages the correct room and both clear friends within the actual viewport")
			hud_layout(game, fixture[0] + (" touch" if touch_mode else " keyboard"), Progress.data.leaves.size(), 6, touch_mode)
			check(not game.objective.is_visible_in_tree() and not game.counter.is_visible_in_tree() and not game.jump_meter.is_visible_in_tree(), fixture[0] + " hides the former header, counters and jump sentence")
			await capture(fixture[0] + ("_touch" if touch_mode else "_keyboard"))
	check(Progress.data == saved, "Reviewing every original HUD view preserves quest and collection progress")
	game.player.sprite.frozen = mark_was_frozen
	game.campus.bark.frozen = bark_was_frozen
	game.set_physics_process(true)
	game.player.set_physics_process(true)
	game.start_tutorial()
	game.dismiss_dialogue()
	await ticks(8)
	check(game.toast_panel.visible and not game.objective.is_visible_in_tree(), "The first lesson is a temporary paper cue rather than a permanent header")
	await ticks(500)
	check(not game.toast_panel.visible and not game.prompt_panel.visible, "An unchanged lesson clears its cue and leaves a quiet screen")
	game.sound_player.stop()
	game.sound_player.stream = null
	await game.soundscape.drain()
	game.queue_free()
	await ticks(3)

func responsive_geometry():
	var parent = Control.new()
	parent.size = Vector2(960, 540)
	add_child(parent)
	var hud = HUD.new()
	parent.add_child(hud)
	hud.safe_insets = Vector4(36, 18, 48, 14)
	hud.update_state(12, 24, 1, true, true)
	await ticks(3)
	hud.score_key = "previously_collected_climb"
	hud.update_state(18, 24, 1, true, true)
	var loaded_without_gain = hud.score == 18 and hud.score_pulse == 0
	hud.update_state(19, 24, 1, true, true)
	check(loaded_without_gain and hud.score == 19 and hud.score_pulse > 0, "Loading another score context is quiet while a new same-context discovery still flourishes")
	var safe = Rect2(36, 18, 960 - 36 - 48, 540 - 18 - 14)
	check(hud.size == Vector2(960, 540) and fits(hud.occupied_rects(), safe), "The HUD reflows inside a small viewport and asymmetric safe insets")
	check(hud.touch_buttons.values().all(func(button): return button.size.x >= 44 and button.size.y >= 44), "Every inset touch action retains at least a 44-pixel hit target")
	parent.size = Vector2(1280, 720)
	await ticks(3)
	check(hud.pause_button.get_global_rect().end.x <= 1280 - 48 and hud.touch_rect("jump").end.y <= 720 - 14, "Resizing preserves right and bottom safe-area clearance")
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.touch_root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Transparent full-screen HUD containers cannot intercept play-area clicks")
	hud.update_state(12, 24, 1, false, false)
	await ticks(2)
	check(not hud.touch_buttons.use.is_visible_in_tree() and hud.occupied_rects().size() == 3, "Hidden touch actions leave no full-screen active hit area")
	parent.queue_free()
	await ticks(3)

func run():
	get_tree().root.size = Vector2i(1280, 720)
	Progress.reset_game(false)
	Mega.reset(false)
	Progress.settings = Progress.SETTING_DEFAULTS.duplicate(true)
	Progress.settings.music = false
	Progress.settings.volume = 0
	Mega.prefs.calm = true
	check(not Progress.save_enabled and not Mega.enabled, "HUD review isolates both persistent adventures")
	await review_climbs()
	await review_story()
	await responsive_geometry()
	check(Art.missing_assets.is_empty(), "Every new HUD illustration resolves")
	check(not Progress.save_enabled and not Mega.enabled, "HUD input and menu checks keep player save guards disabled")
	finish()
