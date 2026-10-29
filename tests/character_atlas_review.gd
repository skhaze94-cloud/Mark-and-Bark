extends Node2D
func ticks(n=3):
	for i in range(n):await get_tree().physics_frame
func _ready():call_deferred("run")
func run():
	get_tree().root.size=Vector2i(1280,720);Progress.save_enabled=false;Mega.enabled=false
	DirAccess.make_dir_recursive_absolute("res://test_output")
	var ids=[]
	for id in Art.index:
		if id.begins_with("young_actions_") or id.begins_with("bark_actions_"):ids.append(id)
	var profiles=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rigs/character_points.json")).profiles
	for id in profiles:
		if id not in ids:ids.append(id)
	for page in range(ceili(ids.size()/6.0)):
		for c in get_children():remove_child(c);c.queue_free()
		var bg=ColorRect.new();bg.color=Color("f3ead4");bg.size=Vector2(1280,720);add_child(bg)
		for n in range(6):
			if page*6+n>=ids.size():continue
			var id=ids[page*6+n];var x=(n%3)*426+213;var y=int(n/3)*360+333
			var sprite=Sprite2D.new();sprite.texture=Art.tex(id);sprite.centered=false;sprite.offset=Vector2(-256,-612);sprite.position=Vector2(x,y);sprite.scale=Vector2.ONE*.46;add_child(sprite)
			var label=Label.new();label.text=id;label.position=Vector2((n%3)*426+12,int(n/3)*360+8);label.add_theme_color_override("font_color",Color("203849"));label.add_theme_font_size_override("font_size",18);label.add_theme_font_override("font",Art.font);add_child(label)
		await ticks();await get_tree().process_frame;await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png("res://test_output/pose_page_"+str(page)+".png")
	get_tree().quit()
