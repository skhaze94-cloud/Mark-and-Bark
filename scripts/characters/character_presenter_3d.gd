extends Node2D
## A true lit 3D scene projected into the established, foot-anchored 2D world.
## Source Sprite2D textures remain available for legacy art, quests and inspection.
const FRAME = Vector2(512, 640)
const RENDER_SIZE = Vector2i(384, 480)
const GAMEPLAY_RENDER_SIZE = Vector2i(256, 320)
var owner_actor: Sprite2D
var viewport: SubViewport
var world: Node3D
var carrier: Node3D
var model: Node3D
var camera: Camera3D
var finishing: Node3D
var performance: Node
var display: Sprite2D
var role: String = "mark"
var active: bool = false
var facing_yaw: float = 0.48
var inspection_yaw: float = 0.0
var _built_role: String = ""
var _was_visible: bool = false
var _was_frozen: bool = false
var _was_reduced: bool = false
var _request_frame: bool = true
var _last_inspection_yaw: float = 0.0

func _ready() -> void:
	name = "Character3D"
	visible = false

func configure(next_role: String, enabled: bool) -> void:
	role = next_role
	active = enabled
	visible = active
	if not active:
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if not is_instance_valid(viewport):
		_build_scene()
	if _built_role != role:
		_build_model()

func _build_scene() -> void:
	viewport = SubViewport.new()
	viewport.name = "CharacterViewport"
	viewport.size = RENDER_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.disable_3d = false
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	world = Node3D.new()
	world.name = "CharacterWorld"
	viewport.add_child(world)
	carrier = Node3D.new()
	carrier.name = "FacingPivot"
	world.add_child(carrier)
	var environment_node = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4e6ef")
	environment.ambient_light_energy = 0.30
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment_node.environment = environment
	world.add_child(environment_node)
	_light("WarmKey", Vector3(-35, -38, 0), Color("fff0df"), 0.75, true)
	_light("CoolFill", Vector3(-14, 135, 0), Color("d5e7f4"), 0.18, false)
	_light("LeafRim", Vector3(-25, -155, 0), Color("fff4df"), 0.22, false)
	camera = Camera3D.new()
	camera.name = "PortraitCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.05
	camera.near = 0.05
	camera.far = 30.0
	world.add_child(camera)
	camera.position = Vector3(0, 1.80, 6.0)
	camera.look_at(Vector3(0, 1.34, 0), Vector3.UP)
	camera.make_current()
	display = Sprite2D.new()
	display.name = "RenderedCharacter"
	display.centered = false
	display.texture = viewport.get_texture()
	display.scale = FRAME / Vector2(RENDER_SIZE)
	add_child(display)
	_align_floor()
	performance = load("res://scripts/characters/character_performance_3d.gd").new()
	performance.name = "CharacterPerformance3D"
	add_child(performance)

func _light(id: String, angles: Vector3, tint: Color, energy: float, casts: bool) -> void:
	var light = DirectionalLight3D.new()
	light.name = id
	light.rotation_degrees = angles
	light.light_color = tint
	light.light_energy = energy
	light.shadow_enabled = casts
	light.shadow_bias = 0.08
	light.shadow_normal_bias = 0.8
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_max_distance = 12.0
	world.add_child(light)

func _build_model() -> void:
	if is_instance_valid(model):
		carrier.remove_child(model)
		model.queue_free()
	var path: String = "res://scripts/characters/" + role + "_model_3d.gd"
	model = load(path).new()
	model.name = "MarkModel3D" if role == "mark" else "BarkModel3D"
	carrier.add_child(model)
	if model.has_method("build"):
		model.build()
	finishing = preload("res://scripts/characters/character_finishing_3d.gd").new()
	model.add_child(finishing)
	finishing.build(model,role)
	performance.bind_model(model)
	_built_role = role
	_request_frame = true

func _align_floor() -> void:
	# Camera projection, not a hand-tuned body offset, defines the shared foot pivot.
	display.position = -camera.unproject_position(Vector3.ZERO) * display.scale

func step(delta: float) -> void:
	if not active or not is_instance_valid(model) or not is_instance_valid(owner_actor):
		return
	# Remove legacy flat-paint mirroring/squash while keeping the same world feet
	# and size. A left turn is an actual 3D rotation through the front of the face.
	var uniform: float = maxf(0.001, absf(owner_actor.scale.x))
	# Small in-world avatars still have roughly twice their displayed resolution.
	# Portraits and the studio retain the larger texture for close inspection.
	var render_size: Vector2i = GAMEPLAY_RENDER_SIZE if uniform < 0.4 else RENDER_SIZE
	if viewport.size != render_size:
		viewport.size = render_size
		display.scale = FRAME / Vector2(render_size)
		_align_floor()
		_request_frame = true
	var desired = Transform2D(0.0, Vector2.ONE * uniform, 0.0, owner_actor.position)
	transform = owner_actor.transform.affine_inverse() * desired
	var facing: float = -1.0 if owner_actor.scale.x < 0 else 1.0
	var target: float = facing * (0.62 if absf(owner_actor.motion.x) > 35 else 0.48) + inspection_yaw
	var still: bool = owner_actor.frozen
	var reduced: bool = owner_actor.reduced_motion
	var inspection_changed: bool = not is_equal_approx(inspection_yaw, _last_inspection_yaw)
	if inspection_changed:
		facing_yaw = target
		_request_frame = true
	elif reduced:
		facing_yaw = target
	elif not still:
		facing_yaw = lerp_angle(facing_yaw, target, 1.0 - exp(-delta * 13.0))
	carrier.rotation.y = facing_yaw
	performance.frozen = still
	performance.reduced_motion = reduced
	performance.playback_rate = owner_actor.playback_rate
	performance.pose_hint = owner_actor.displayed_pose
	performance.drive(owner_actor.mode, owner_actor.grounded, owner_actor.motion, owner_actor.cadence)
	performance.advance(delta)
	finishing.advance(delta * owner_actor.playback_rate, owner_actor.motion, still, reduced)
	var on_screen: bool = owner_actor.is_visible_in_tree() and _on_screen()
	if not on_screen:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	elif not still:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	elif _request_frame or not _was_visible or not _was_frozen or reduced != _was_reduced:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_was_visible = on_screen
	_was_frozen = still
	_was_reduced = reduced
	_last_inspection_yaw = inspection_yaw
	_request_frame = false

func _on_screen() -> bool:
	var feet: Vector2 = owner_actor.get_global_transform_with_canvas().origin
	var magnitude: Vector2 = owner_actor.get_global_transform_with_canvas().get_scale().abs()
	var bounds = Rect2(feet - Vector2(320, 640) * magnitude, Vector2(640, 680) * magnitude)
	return bounds.intersects(owner_actor.get_viewport_rect().grow(64))

func pulse(name: String, seconds: float) -> void:
	if is_instance_valid(performance):
		performance.pulse(name, seconds)
		_request_frame = true

func land(strength: float) -> void:
	if is_instance_valid(performance):
		performance.land(strength)
		_request_frame = true

func reset_motion() -> void:
	if is_instance_valid(performance):
		performance.reset_motion()
		_request_frame = true

func request_frame() -> void:
	_request_frame = true

func stop_rendering() -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_was_visible = false

func projected_joint(id: String) -> Vector2:
	if not is_instance_valid(model) or not is_instance_valid(camera):
		return Vector2.ZERO
	var point: Vector3 = Vector3.ZERO
	if id != "origin":
		var node = model.joints.get(id)
		if not is_instance_valid(node):
			node = model.joints.get("head")
		if is_instance_valid(node):
			point = node.global_position
	# Transform into the semantic Sprite2D's coordinates for existing overlays.
	var local: Vector2 = display.position + camera.unproject_position(point) * display.scale
	return transform * local
