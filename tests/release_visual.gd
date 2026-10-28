extends Node
var game
func ticks(n=3):
	for i in range(n):await get_tree().physics_frame
func capture(label):
	await ticks(4);await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/release31_"+label+".png")
func _ready():call_deferred("run")
func run():
	await ticks();get_tree().root.size=Vector2i(1280,720);Mega.enabled=false;Mega.reset(false);Mega.prefs.calm=false;Progress.save_enabled=false
	DirAccess.make_dir_recursive_absolute("res://test_output")
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(4)
	await capture("title");game.level_select();await capture("levels");game.title()
	game.how_to_play(game.title);await capture("controls");game.close()
	game.load_level(0);await ticks(14);game.journal();await capture("notebook");game.close()
	game.settings(game.close);await capture("settings");game.close()
	for i in range(3):
		game.load_level(i);await ticks(14);await capture("floor_"+str(i))
		var rect=game.campus.platforms[10];game.last_shelf=11;game.place_player(Vector2(rect.get_center().x,rect.position.y-3))
		game.campus.last_safe=game.player.position;game.campus.safe_shelf=11;await ticks(75);await capture("climb_"+str(i))
	var summit=game.campus.platforms[game.campus.RISES[2].size()-1];game.place_player(Vector2(summit.get_center().x,summit.position.y-3));game.last_shelf=33;await ticks(8);game.jump();await ticks(26);game.jump();await ticks(26);await capture("above_summit")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4);get_tree().quit()
