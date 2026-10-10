extends Node

# Deterministic visual fixtures. Never overwrite the player's save file.
var game

func _ready() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in range(12):await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test_output/"+name+".png")

func run() -> void:
	Progress.save_enabled=false
	Progress.reset_game(false)
	Progress.tutorial_done=false
	Progress.settings.reduced_motion=false
	Progress.settings.touch=false
	DirAccess.make_dir_recursive_absolute("res://test_output")
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await capture("polish_title")
	if "--title-only" in OS.get_cmdline_user_args():
		await game.soundscape.drain()
		get_tree().quit()
		return
	game.shrinking_intro.begin(game.start_tutorial)
	game.shrinking_intro.age=2.0
	game.shrinking_intro.update_story()
	await capture("polish_ray_before")
	game.shrinking_intro.age=5.3
	game.shrinking_intro.update_story()
	await capture("polish_ray_shrink")
	game.shrinking_intro.age=8.0
	game.shrinking_intro.update_story()
	await capture("polish_ray_after")
	game.shrinking_intro.finish()
	game.dismiss_dialogue()
	game.start_tutorial()
	game.dismiss_dialogue()
	game.player.position=Vector2(670,605)
	await capture("polish_tutorial")
	Progress.data.stage=1
	game.start_campus()
	game.player.position=Vector2(790,605)
	game.sync_room()
	game.toast_time=0
	await capture("polish_hallway")
	Progress.data.stage=3
	Progress.data.notebook=true
	Progress.data.plant=true
	Progress.data.plant_restored=true
	game.player.position=Vector2(2800,605)
	game.sync_room()
	game.campus.refresh()
	await capture("polish_garden")
	game.player.position=Vector2(2500,255)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await capture("polish_leaf_tops")
	game.player.position=Vector2(2740,400)
	game.player.velocity=Vector2(0,-150)
	game.player.jumps_used=1
	game.jump_pressed()
	await capture("polish_leafy_lift")
	game.begin_room_transition(2,4240,"Into the invention workshop")
	game.room_transition.age=0.22
	await capture("polish_transition")
	game.cancel_room_transition()
	game.player.enabled=true
	Progress.data.stage=6
	Progress.data.books=true
	Progress.data.pencil=true
	Progress.data.assembled=3
	game.player.position=Vector2(4490,605)
	game.sync_room()
	game.campus.refresh()
	await capture("polish_workshop")
	game.player.position=Vector2(5310,260)
	game.player.velocity=Vector2.ZERO
	game.player.reset_jumps()
	game.sync_room()
	await capture("polish_pencil_express")
	game.jump_pressed()
	for i in range(27):await get_tree().physics_frame
	game.jump_pressed()
	for i in range(22):await get_tree().physics_frame
	await capture("polish_high_jump")
	game.player.velocity=Vector2.ZERO
	game.player.position=Vector2(4930,605)
	game.sync_room()
	await capture("polish_live_board")
	Progress.data.assembled=1
	game.show_workshop()
	await capture("polish_assembly")
	Progress.data.assembled=3
	game.show_workshop()
	await capture("polish_workshop_ui")
	game.close_modal()
	game.show_settings(game.show_title)
	await capture("polish_settings")
	game.close_modal()
	Progress.data.completed=true
	Progress.data.attempts=2
	Progress.data.stage=7
	game.show_ending()
	await capture("polish_ending")
	game.celebration.active=false
	game.celebration.hide()
	game.close_modal()
	Progress.settings.touch=true
	game.apply_settings()
	await capture("polish_touch")
	game.cinema.begin(game.return_from_film)
	for spec in [[2.0,"garden"],[9.0,"hallway"],[16.0,"workshop"],[23.0,"finale"]]:
		game.cinema.age=spec[0]
		game.cinema.update_shot()
		await capture("polish_film_"+spec[1])
	game.cinema.finish()
	print("Visual fixtures captured")
	await game.soundscape.drain()
	game.queue_free()
	for i in range(5):await get_tree().physics_frame
	get_tree().quit()
