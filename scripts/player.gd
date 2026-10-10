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
	queue_redraw()
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

func _draw() -> void:
	var height = maxf(0.0,610.0-position.y)
	var radius = 30.0 * clampf(1.0-height/450.0,0.45,1.0)
	var points = PackedVector2Array()
	for i in range(32):
		points.append(Vector2(cos(i*TAU/32)*radius,610.0-position.y+sin(i*TAU/32)*7))
	draw_colored_polygon(points,Color(0.09,0.14,0.13,0.23))

