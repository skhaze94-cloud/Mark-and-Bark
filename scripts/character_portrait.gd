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
		var eyes: Vector2=(actor.rest_points.eye_near+actor.rest_points.eye_far)*.5
		var renderer=actor.get("character3d")
		if is_instance_valid(renderer) and renderer.get("active")==true:
			# Align the real 3D gaze with the same portrait framing as the painting.
			var near: Vector2=renderer.projected_joint("eye_near")
			var far: Vector2=renderer.projected_joint("eye_far")
			eyes=(near+far)*.5 if not near.is_zero_approx() and not far.is_zero_approx() else renderer.projected_joint("head")
		actor.scale=Vector2.ONE*factor
		actor.position=Vector2(size.x*.5,size.y*.43)-eyes*factor
		actor.drive("talk",true)
