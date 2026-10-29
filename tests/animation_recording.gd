extends Node
# Reproducible footage of actual campaign physics, not a replacement jump path.
var game
func ticks(n):
	for i in range(n):await get_tree().physics_frame
func _ready():call_deferred("record")
func _process(_delta):
	if not is_instance_valid(game):return
	game.camera.zoom=Vector2(2,2)
	game.camera.position=game.player.position+Vector2(35,-105)
func record():
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=false
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);game.load_level(0);game.hud.hide();game.overlay.hide()
	var canvas=CanvasLayer.new();canvas.layer=40;add_child(canvas)
	var panel=ColorRect.new();panel.color=Color("203849");panel.size=Vector2(1280,82);canvas.add_child(panel)
	var heading=Label.new();heading.position=Vector2(32,13);heading.size=Vector2(1220,60);heading.text="MARK & BARK 3.2    /    LIVE GAMEPLAY\nImmediate jumps · a leafy spring · a soft landing";heading.add_theme_font_override("font",Art.font);heading.add_theme_font_size_override("font_size",21);heading.add_theme_color_override("font_color",Color("fff3d3"));canvas.add_child(heading)
	await ticks(50)
	for shelf in range(3):
		var target=game.campus.platforms[shelf];game.jump();var landed=false
		for t in range(150):
			var dx=target.get_center().x-game.player.position.x
			Input.action_release("left");Input.action_release("right")
			if absf(dx)>7:Input.action_press("right" if dx>0 else "left")
			if t==24:game.jump()
			await ticks(1)
			if t>28 and game.player.is_on_floor() and absf(game.player.position.y-target.position.y)<6:landed=true;break
		Input.action_release("left");Input.action_release("right")
		if not landed:push_error("Recording jump failed to reach shelf "+str(shelf+1));get_tree().quit(1);return
		await ticks(35)
	await ticks(55)
	print("RECORDING: three shelves reached with actual double-jump physics")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();get_tree().quit()
