extends Node2D
var mark
var bark
func ticks(n=3):
	for i in range(n):await get_tree().physics_frame
func capture(label):
	await ticks(3);await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/rig_"+label+".png")
func _ready():call_deferred("run")
func run():
	Progress.save_enabled=false;Mega.enabled=false;Progress.settings.reduced_motion=false
	DirAccess.make_dir_recursive_absolute("res://test_output")
	var bg=ColorRect.new();bg.color=Color("f3ead4");bg.size=Vector2(1280,720);add_child(bg)
	mark=Art.character("young_actions_idle");mark.position=Vector2(360,660);mark.scale=Vector2.ONE*.9;add_child(mark)
	bark=Art.character("bark_actions_idle");bark.position=Vector2(910,660);bark.scale=Vector2.ONE*1.15;add_child(bark)
	await ticks(4);await capture("idle")
	mark.manual_pose=true;bark.manual_pose=true;mark.bones.EyeNear.scale.y=.03;mark.bones.EyeFar.scale.y=.03;bark.bones.EyeNear.scale.y=.03;bark.bones.EyeFar.scale.y=.03;await capture("blink")
	mark.show_points=true;bark.show_points=true;await capture("points")
	mark.manual_pose=false;bark.manual_pose=false;mark.show_points=false;bark.show_points=false
	mark.texture=Art.tex("young_actions_jump");bark.texture=Art.tex("bark_actions_hop");mark.drive("spring_release",false,Vector2(120,-450),0);bark.drive("spring_release",false,Vector2(120,-450),0);await ticks(5);await capture("spring")
	get_tree().quit()
