extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	Progress.save_enabled=false
	var game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	for i in range(5):await get_tree().process_frame
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	if not game.quitting or not game.soundscape.stopped:
		push_error("Window-close audio shutdown did not start")
		get_tree().quit(1)
	else:
		print("PASS: Window close starts clean audio shutdown")
