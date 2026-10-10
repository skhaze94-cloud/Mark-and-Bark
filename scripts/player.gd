extends CharacterBody2D

const SPEED = 260.0
const GRAVITY = 1250.0
const JUMP = -570.0
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
	capsule.radius = 18
	capsule.height = 125
	shape.shape = capsule
	shape.position.y = -62.5
	add_child(shape)
	sprite = Art.character("young_actions_idle")
	sprite.scale = Vector2.ONE * 0.31
	add_child(sprite)
	z_index = 3
	collision_layer = 2
	collision_mask = 1

func request_jump() -> void:
	jump_queued = true

func show_pose(id: String, seconds: float = 0.5) -> void:
	sprite.texture = Art.tex(id)
	pose_lock = seconds

func _physics_process(delta: float) -> void:
	anim += delta
	stride += absf(velocity.x) * delta
	landing=maxf(0.0,landing-delta)
	for mote in dust:mote.age+=delta
	dust=dust.filter(func(m):return m.age<0.32)
	queue_redraw()
	var was_grounded=is_on_floor()
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
		if jump_buffer > 0 and coyote > 0:
			velocity.y = JUMP
			jump_buffer = 0
			coyote = 0
	velocity.y += GRAVITY*delta
	move_and_slide()
	if is_on_floor() and not was_grounded and fall_speed>180 and not reduced_motion:
		landing=0.16
		dust.append({"at":global_position,"age":0.0})
	position.x = clampf(position.x,40,right_bound-40)
	if absf(velocity.x)>10:
		facing = 1 if velocity.x>0 else -1
	sprite.scale.x = 0.31*facing
	pose_lock -= delta
	if pose_lock <= 0:
		var pose = "young_actions_idle"
		if not is_on_floor():
			pose = "young_actions_jump"
		elif absf(velocity.x)>35:
			var frames = ["young_actions_walk_stride_a","young_actions_walk_passing","young_actions_walk_stride_b","young_actions_walk_passing"]
			pose = frames[int(stride / 35.0) % 4]
		sprite.texture = Art.tex(pose)
	# All transforms pivot at the supplied feet, so idle breathing never slides.
	sprite.position.y = 0.0
	if reduced_motion:
		sprite.rotation = 0
		sprite.scale.y = 0.31
	else:
		sprite.rotation = velocity.x / SPEED * 0.025 if is_on_floor() else clampf(velocity.y / 12000.0,-0.035,0.035)
		sprite.scale.y = 0.31 * (1.0 + sin(anim * 2.1) * 0.008) if absf(velocity.x)<35 and is_on_floor() else 0.31
		if landing>0:
			var settle=sin(landing/0.16*PI)*0.055
			sprite.scale.y*=1.0-settle
			sprite.scale.x*=1.0+settle*0.5

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
		for mote in dust:
			var local: Vector2=mote.at-global_position
			for i in range(6):
				var outward=(i-2.5)*9.0*(1.0+mote.age*3)
				draw_circle(local+Vector2(outward,-sin(mote.age/0.32*PI)*7),2.4,Color(0.90,0.80,0.60,(1.0-mote.age/0.32)*0.32))

