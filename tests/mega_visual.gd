extends Node
var game
func ticks(n=2):
	for i in range(n):await get_tree().physics_frame
func shot(name):
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/"+name+".png")
func _ready():call_deferred("run")
func run():
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=true
	DirAccess.make_dir_recursive_absolute("res://test_output")
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(5);await shot("mega_final_title")
	for i in range(3):
		game.load_level(i);await ticks(8);await shot("mega_final_level_"+str(i+1))
	game.load_level(0);await ticks(8);Progress.settings.reduced_motion=false;game.jump();await ticks(26);game.jump();await ticks(4);await shot("mega_final_contact");await ticks(10);await shot("mega_final_release")
	game.retry();await ticks(8);game.pause_game();await shot("mega_final_pause");game.settings(func():game.close());await shot("mega_final_settings")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4);print("MEGA VISUAL: 8 fixtures captured");get_tree().quit()
