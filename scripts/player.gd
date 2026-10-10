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
	collision_layer = 2
	collision_mask = 1

func request_jump() -> void:
	jump_queued = true

func show_pose(id: String, seconds: float = 0.5) -> void:
	sprite.texture = Art.tex(id)
	pose_lock = seconds

func _physics_process(delta: float) -> void:
	anim += delta
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
			# Alternating readable poses with low frequency avoids jittery feet.
			pose = "young_actions_walk_stride_a" if int(anim*5)%2==0 else "young_actions_walk_passing"
		sprite.texture = Art.tex(pose)
	sprite.position.y = 0.0 if reduced_motion or absf(velocity.x)<35 else sin(anim*10)*1.5

