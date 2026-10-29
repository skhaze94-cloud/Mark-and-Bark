extends TextureRect
var actor: Sprite2D
func _ready():
	self_modulate.a=0;clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	actor=Art.game_actor("young_actions_notebook");add_child(actor)
func _process(_delta):
	if not is_instance_valid(actor):return
	actor.texture=texture
	if actor.has_method("drive"):
		actor.sync_pose()
		var factor=(.48 if actor.role=="mark" else .60)*minf(size.x/135.0,size.y/180.0)
		var eyes=(actor.rest_points.eye_near+actor.rest_points.eye_far)*.5
		actor.scale=Vector2.ONE*factor
		actor.position=Vector2(size.x*.5,size.y*.43)-eyes*factor
		actor.drive("talk",true)
