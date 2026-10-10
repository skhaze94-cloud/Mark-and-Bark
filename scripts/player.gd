extends CharacterBody2D

const SPEED = 260.0
const GRAVITY = 1250.0
const JUMP = -620.0
const AIR_JUMP = -590.0
signal jumped(is_second: bool)
# Companions update after movement, keeping contact aligned with the feet.
signal movement_finished(delta: float)
signal landed(at: Vector2, strength: float)
var spring_contact: bool = false
var suspended: bool = false
var ghost: Sprite2D
var last_texture: Texture2D
var blend_age: float = 1.0
var jump_stretch: float = 0.0
var visual_scale: float = 0.24
var jumps_used: int = 0
var double_jump_count: int = 0
var air_rings: Array[Dictionary] = []
var sprite: Sprite2D
var enabled: bool = true
var reduced_motion: bool = false
var axis: float = 0.0
var jump_queued: bool = false
var facing: int = 1
var coyote: float = 0.0
var jump_buffer: float = 0.0
var anim: float = 0.0
var right_bound: float = 5500.0
var pose_lock: float = 0.0
var stride: float = 0.0
var landing: float = 0.0
var dust: Array[Dictionary] = []

func _ready() -> void:
	var shape = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 14
	capsule.height = 96
	shape.shape = capsule
	shape.position.y = -48.0
	add_child(shape)
	sprite = Art.character("young_actions_idle")
	sprite.scale = Vector2.ONE * visual_scale
	add_child(sprite)
	ghost=Art.character("young_actions_idle")
	ghost.z_index=-1
	ghost.hide()
	add_child(ghost)
	last_texture=sprite.texture
	z_index = 3
	collision_layer = 2
	collision_mask = 1

func request_jump() -> void:
	jump_queued = true

func show_pose(id: String, seconds: float = 0.5) -> void:
	sprite.texture = Art.tex(id)
	pose_lock = seconds

func _physics_process(delta: float) -> void:
	if suspended:
		axis=0
		jump_queued=false
		jump_buffer=0
		return
	anim += delta
	jump_stretch=maxf(0.0,jump_stretch-delta)
	stride += absf(velocity.x) * delta
	landing=maxf(0.0,landing-delta)
	for mote in dust:mote.age+=delta
	dust=dust.filter(func(m):return m.age<0.32)
	queue_redraw()
	for ring in air_rings:ring.age+=delta
	air_rings=air_rings.filter(func(r):return r.age<0.45)
	var was_grounded=is_on_floor()
	if was_grounded:
		jumps_used=0
	var fall_speed=velocity.y
	if not enabled:
		velocity.x = move_toward(velocity.x,0,1400*delta)
		jump_queued = false
		jump_buffer = 0
	else:
		if jump_queued:
			jump_buffer = 0.16
		jump_queued = false
		jump_buffer -= delta
		coyote = 0.14 if is_on_floor() else coyote-delta
		velocity.x = move_toward(velocity.x,axis*SPEED,1800*delta)
		if jump_buffer > 0:
			if coyote > 0 and jumps_used==0:
				velocity.y = JUMP
				jumps_used=1
				jump_buffer=0
				coyote=0
				jump_stretch=0.14
				jumped.emit(false)
			elif not is_on_floor() and jumps_used<2:
				# Walking off a ledge still leaves one rescue jump.
				velocity.y=AIR_JUMP
				jumps_used=2
				jump_buffer=0
				coyote=0
				double_jump_count+=1
				if not reduced_motion:air_rings.append({"at":global_position,"age":0.0})
				jump_stretch=0.14
				jumped.emit(true)
	velocity.y += GRAVITY*delta
	move_and_slide()
	if is_on_floor() and not was_grounded and fall_speed>180:
		landed.emit(global_position,clampf(fall_speed/700.0,0.2,1.0))
		if not reduced_motion:
			landing=0.16
			dust.append({"at":global_position,"age":0.0})
	position.x = clampf(position.x,40,right_bound-40)
	if absf(velocity.x)>10:
		facing = 1 if velocity.x>0 else -1
	sprite.scale.x = visual_scale*facing
	pose_lock -= delta
	if pose_lock <= 0:
		var pose = "young_actions_idle"
		if not is_on_floor():
			pose = "young_actions_jump"
		elif absf(velocity.x)>35:
			var frames = ["young_actions_walk_stride_a","young_actions_walk_passing","young_actions_walk_stride_b","young_actions_walk_passing"]
			if absf(velocity.x)>200:
				frames=["young_actions_run_stride_a","young_actions_run_passing","young_actions_run_stride_b","young_actions_run_flight"]
			pose = frames[int(stride / 43.0) % 4]
		sprite.texture = Art.tex(pose)
	# All transforms pivot at the supplied feet, so idle breathing never slides.
	sprite.position.y = 0.0
	if reduced_motion:
		sprite.rotation = 0
		sprite.scale.y = visual_scale
	else:
		sprite.rotation = velocity.x / SPEED * 0.025 if is_on_floor() else clampf(velocity.y / 12000.0,-0.035,0.035)
		sprite.scale.y = visual_scale * (1.0 + sin(anim * 2.1) * 0.008) if absf(velocity.x)<35 and is_on_floor() else visual_scale
		if jump_stretch>0:
			sprite.scale.y*=1.0+sin(jump_stretch/0.14*PI)*0.045
		if landing>0:
			var settle=sin(landing/0.16*PI)*0.055
			sprite.scale.y*=1.0-settle
			sprite.scale.x*=1.0+settle*0.5

	# A short crossfade smooths the supplied key poses, with identical foot pivots.
	if sprite.texture!=last_texture:
		ghost.texture=last_texture
		last_texture=sprite.texture
		blend_age=0.0
	blend_age+=delta
	var mix=1.0 if reduced_motion or spring_contact else clampf(blend_age/0.065,0,1)
	sprite.modulate.a=mix
	ghost.modulate.a=1.0-mix
	ghost.visible=mix<1
	ghost.scale=sprite.scale
	ghost.rotation=sprite.rotation
	ghost.position=sprite.position
	movement_finished.emit(delta)

func _draw() -> void:
	var support: float=get_parent().campus.support_y(position.x,position.y)
	var height = maxf(0.0,support-position.y)
	var radius = 30.0 * clampf(1.0-height/450.0,0.45,1.0)
	for layer in range(4):
		var points = PackedVector2Array()
		var spread=1.0-layer*0.12
		for i in range(32):
			points.append(Vector2(height*0.06+cos(i*TAU/32)*radius*spread,support-position.y+sin(i*TAU/32)*7*spread))
		draw_colored_polygon(points,Color(0.09,0.14,0.13,0.065*clampf(1.0-height/500.0,0.45,1.0)))
	if not reduced_motion:
		for ring in air_rings:
			var age: float=ring.age/0.45
			draw_arc(ring.at-global_position+Vector2(0,-12),18+age*32,0,TAU,32,Color(0.93,0.79,0.40,(1-age)*0.65),3)
		for mote in dust:
			var local: Vector2=mote.at-global_position
			for i in range(6):
				var outward=(i-2.5)*9.0*(1.0+mote.age*3)
				draw_circle(local+Vector2(outward,-sin(mote.age/0.32*PI)*7),2.4,Color(0.90,0.80,0.60,(1.0-mote.age/0.32)*0.32))



func reset_jumps() -> void:
	spring_contact=false
	jumps_used=0
	coyote=0
	jump_buffer=0
	jump_queued=false
	air_rings.clear()
	jump_stretch=0
	blend_age=1
	if is_instance_valid(ghost):ghost.hide()
