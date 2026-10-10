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
	await capture("v2_title")
	game.start_tutorial()
	game.dismiss_dialogue()
	game.player.position=Vector2(670,605)
	await capture("v2_tutorial")
	Progress.data.stage=1
	game.start_campus()
	game.player.position=Vector2(790,605)
	game.sync_room()
	game.toast_time=0
	await capture("v2_hallway")
	Progress.data.stage=3
	Progress.data.notebook=true
	Progress.data.plant=true
	Progress.data.plant_restored=true
	game.player.position=Vector2(2800,605)
	game.sync_room()
	game.campus.refresh()
	await capture("v2_garden")
	game.begin_room_transition(2,4240,"Into the invention workshop")
	game.room_transition.age=0.22
	await capture("v2_transition")
	game.cancel_room_transition()
	game.player.enabled=true
	Progress.data.stage=6
	Progress.data.books=true
	Progress.data.pencil=true
	Progress.data.assembled=3
	game.player.position=Vector2(4490,605)
	game.sync_room()
	game.campus.refresh()
	await capture("v2_workshop")
	game.show_workshop()
	await capture("v2_workshop_ui")
	game.close_modal()
	Progress.settings.touch=true
	game.apply_settings()
	await capture("v2_touch")
	print("Visual fixtures captured")
	get_tree().quit()
