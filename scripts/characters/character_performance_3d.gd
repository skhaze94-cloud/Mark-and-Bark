extends Node
## Display-only performance for the actual 3D models. The 2D controller owns all
## movement/collision. The presenter calls advance() once with unscaled delta.
var model: Node3D
var joints: Dictionary = {}
var rest: Dictionary = {}
var role: String = "mark"
var mode: String = "idle"
var active_state: String = "idle"
var pose_hint: String = ""
var grounded: bool = true
var motion: Vector2 = Vector2.ZERO
var cadence: float = 0.0
var age: float = 0.0
var state_age: float = 0.0
var event_age: float = 9.0
var landing_age: float = 9.0
var landing_force: float = 0.0
var emote: String = ""
var emote_left: float = 0.0
var frozen: bool = false
var reduced_motion: bool = false
var playback_rate: float = 1.0
var blink_value: float = 0.0
var gaze: Vector2 = Vector2.ZERO
var mouth_open: float = 0.0
var smile: float = 0.5
var brow: float = 0.0
var applied_positions: Dictionary = {}
var _angles: Dictionary = {}
var _positions: Dictionary = {}
var _legs: Dictionary = {}
var _last_state: String = ""
var _last_prop_state: String = ""
var _last_reduced: bool = false
var friend_direction: float = 0.0
var friend_left: float = 0.0

func bind_model(value: Node3D) -> void:
	model = value
	if model.has_method("build"):
		model.call("build")
	joints = model.get("joints")
	role = "bark" if model.get_script().resource_path.get_file().begins_with("bark_") else "mark"
	rest.clear()
	for key in joints:
		if is_instance_valid(joints[key]):
			rest[key] = joints[key].transform
	_cache_legs()
	reset_motion()

func drive(next_mode, is_grounded, velocity = Vector2.ZERO, gait = 0.0) -> void:
	var next: String = str(next_mode)
	if next != mode:
		state_age = 0.0
		if next == "land":
			land(0.65)
	mode = next
	grounded = bool(is_grounded)
	motion = velocity
	cadence = float(gait)

func pulse(name, seconds = 0.55) -> void:
	emote = str(name)
	emote_left = maxf(0.0, float(seconds))
	event_age = 0.0

func land(strength) -> void:
	landing_age = 0.0
	landing_force = clampf(float(strength), 0.0, 1.0)

func reset_motion() -> void:
	mode = "idle"
	active_state = "idle"
	motion = Vector2.ZERO
	grounded = true
	age = 0.0
	state_age = 0.0
	event_age = 9.0
	landing_age = 9.0
	emote_left = 0.0
	friend_left = 0.0
	_angles.clear()
	_positions.clear()
	_last_state = ""
	_last_prop_state = ""
	if is_instance_valid(model):
		_restore_rest()
		_apply_pose(0.0, true)

func advance(delta: float) -> void:
	if not is_instance_valid(model):
		return
	if frozen:
		# An accessibility change made in paused Settings still takes effect.
		if reduced_motion != _last_reduced:
			_apply_pose(0.0, true)
		_last_reduced = reduced_motion
		return
	var step: float = clampf(delta * maxf(0.0, playback_rate), 0.0, 0.1)
	age += step
	state_age += step
	event_age += step
	landing_age += step
	emote_left = maxf(0.0, emote_left - step)
	friend_left = maxf(0.0, friend_left - step)
	_apply_pose(step, reduced_motion != _last_reduced)
	_last_reduced = reduced_motion

func joint_position(key: String) -> Vector3:
	if not joints.has(key):
		return Vector3.ZERO
	return model.to_local(joints[key].global_position)

func _restore_rest() -> void:
	for key in rest:
		joints[key].transform = rest[key]

func _cache_legs() -> void:
	_legs.clear()
	for side in ["near", "far"]:
		var keys: Array = ["thigh_" + side, "knee_" + side, "ankle_" + side]
		if not keys.all(func(key): return joints.has(key)):
			continue
		var upper: Vector3 = rest[keys[1]].origin
		var lower: Vector3 = rest[keys[2]].origin
		var lower_vector: Vector3 = rest[keys[1]].basis * lower
		var upper_angle: float = atan2(-upper.z, -upper.y)
		var foot: Vector3 = joint_position(keys[2])
		var hip: Vector3 = joint_position(keys[0])
		var reach: float = 0.12
		if joints.has("toe_" + side):
			reach = maxf(0.08, absf(joint_position("toe_" + side).z - foot.z) * 1.35)
		var contacts: Array[Vector3] = []
		for z in [-reach * 0.55, reach]:
			var on_floor: Vector3 = Vector3(foot.x, 0.0, foot.z + z)
			contacts.append(joints[keys[2]].to_local(model.to_global(on_floor)))
		_legs[side] = {"upper": maxf(0.025, upper.length()), "lower": maxf(0.025, lower.length()),
			"upper_angle": upper_angle, "knee_angle": atan2(-lower_vector.z, -lower_vector.y) - upper_angle,
			"foot": foot, "hip": hip, "contacts": contacts}

func _rotate(key: String, target: Vector3, delta: float, immediate: bool = false) -> void:
	if not joints.has(key):
		return
	var response: float = 1.0 if immediate else 1.0 - exp(-delta * 20.0)
	var previous: Vector3 = _angles.get(key, target)
	var angle: Vector3 = previous.lerp(target, response)
	_angles[key] = angle
	var base: Transform3D = rest[key]
	joints[key].rotation = base.basis.get_euler() + angle

func _translate(key: String, target: Vector3, delta: float, immediate: bool = false) -> void:
	if not joints.has(key):
		return
	var response: float = 1.0 if immediate else 1.0 - exp(-delta * 24.0)
	var previous: Vector3 = _positions.get(key, target)
	var offset: Vector3 = previous.lerp(target, response)
	_positions[key] = offset
	joints[key].position = rest[key].origin + offset

func _state() -> String:
	var result: String = mode
	if emote_left > 0 and mode in ["idle", "walk", "run"]:
		result = emote
	if mode in ["idle", "talk", "hint"]:
		if pose_hint.ends_with("_notebook") or pose_hint.ends_with("_carry"):
			result = "notebook"
		elif pose_hint.ends_with("_cheer"):
			result = "celebrate"
		elif pose_hint.ends_with("_hint") or pose_hint.ends_with("_point"):
			result = "hint"
	return result

func _apply_pose(delta: float, immediate: bool = false) -> void:
	_restore_rest()
	active_state = _state()
	if active_state != _last_state:
		_last_state = active_state
		state_age = 0.0
	var moving: bool = active_state in ["walk", "run"] and grounded
	var running: bool = active_state == "run"
	var still: float = 0.0 if reduced_motion else 1.0
	var flourish: float = 0.4 if reduced_motion else 1.0
	var phase: float = cadence * (2.1 if role == "bark" else 1.35)
	var speed: float = clampf(absf(motion.x) / 260.0, 0.0, 1.0)
	var bob: float = sin(age * 2.15) * 0.012 * still
	var landing: float = maxf(0.0, 1.0 - landing_age / 0.32) * landing_force
	var brace: float = 1.0 if active_state in ["anticipate", "spring_contact"] else 0.0
	var hip_rotation: Vector3 = Vector3(0.0, sin(age * 0.9) * 0.025 * still, 0.0)
	var head_rotation: Vector3 = Vector3(bob * -0.6, sin(age * 0.62) * 0.045 * still, sin(age * 1.37) * 0.012 * still)
	var arm_swing: float = sin(phase) * (0.67 if running else 0.46) * (0.75 if reduced_motion else 1.0)
	var hip_drop: float = landing * (0.11 if role == "bark" else 0.15)
	var targets: Dictionary = {}
	if moving:
		hip_rotation = Vector3((0.12 if running else 0.065) * flourish, sin(phase) * 0.045 * still, sin(phase) * 0.024 * still)
		head_rotation = Vector3(-0.045 * flourish, -sin(phase) * 0.028 * still, -sin(phase) * 0.012 * still)
		for side in ["near", "far"]:
			if not _legs.has(side):
				continue
			var leg: Dictionary = _legs[side]
			var offset: float = 0.0 if side == "near" else PI
			var p: float = fposmod(phase + offset, TAU)
			var ratio: float = p / PI
			var length: float = float(leg.upper) + float(leg.lower)
			var stride: float = length * (0.59 if running else 0.46) * (0.76 if reduced_motion else 1.0)
			var travel: float
			var lift: float = 0.0
			var roll: float = 0.0
			if p < PI:
				# The stance foot travels steadily backwards relative to the body.
				travel = lerpf(stride, -stride, ratio)
				roll = smoothstep(0.62, 1.0, ratio) * 0.20 - (1.0 - smoothstep(0.0, 0.2, ratio)) * 0.08
			else:
				var swing: float = ratio - 1.0
				travel = -stride * cos(swing * PI)
				lift = sin(swing * PI) * length * (0.27 if running else 0.16) * (0.65 if reduced_motion else 1.0)
				roll = -sin(swing * PI) * 0.12
			var target: Vector3 = leg.foot + Vector3(0, lift, travel)
			targets[side] = {"point": target, "roll": roll}
			var vertical: float = leg.hip.y - target.y
			var available: float = sqrt(maxf(0.01, length * length - travel * travel)) * 0.985
			hip_drop = maxf(hip_drop, maxf(0.0, vertical - available))
	else:
		for side in _legs:
			targets[side] = {"point": _legs[side].foot, "roll": 0.0}
	if brace > 0:
		hip_drop += (0.11 if role == "bark" else 0.16) * flourish
		hip_rotation.x = 0.13 * flourish
		head_rotation.x = -0.035 * flourish
	if active_state in ["delight", "celebrate", "cheer"]:
		hip_rotation.z = sin(age * 5.0) * 0.035 * still
		head_rotation = Vector3(-0.08 * flourish, sin(age * 2.7) * 0.07 * still, sin(age * 4.6) * 0.025 * still)
	if active_state in ["talk", "hint", "notebook"]:
		head_rotation.x = (0.05 if active_state == "notebook" else -0.02) + sin(age * 3.1) * 0.025 * still
		head_rotation.y = sin(age * 1.4) * 0.07 * still
	if active_state in ["hint","curious"]:
		head_rotation.z = -.09 * flourish
	if friend_left>0:
		head_rotation.y = friend_direction*.24
		head_rotation.z = -friend_direction*.035
	_rotate("hips", hip_rotation, delta, immediate)
	_translate("hips", Vector3(0, -hip_drop, 0), delta, immediate)
	_rotate("spine", Vector3(bob, 0.0, -hip_rotation.z * 0.55), delta, immediate)
	if role=="bark":
		var stretch: float=1.0
		if active_state in ["delight","celebrate","cheer"]:
			stretch += sin(state_age*6.0)*.045*still
		elif active_state in ["spring_contact","anticipate"]:stretch -= .06*flourish
		elif active_state=="spring_release":stretch += .055*flourish
		joints.spine.scale=rest.spine.basis.get_scale()*Vector3(1.0+(1.0-stretch)*.4,stretch,1.0)
	_rotate("neck", Vector3(-bob * 0.5, 0.0, 0.0), delta, immediate)
	_rotate("head", head_rotation, delta, immediate)
	for side in ["near", "far"]:
		var sign_side: float = -1.0 if side == "near" else 1.0
		var swing: float = arm_swing * (-sign_side) if moving else sin(age * 1.9 + sign_side) * 0.018 * still
		var arm: Vector3 = Vector3(swing, 0, sign_side * (0.30 if role=="bark" else 0.04))
		var elbow: Vector3 = Vector3(-0.16 - absf(swing) * 0.22, 0.0, 0.0)
		var wrist: Vector3 = Vector3(0.02, sin(age * 3.2 + sign_side) * 0.025 * still, 0.0)
		if brace > 0:
			arm = Vector3(-0.35, 0.0, sign_side * 0.45) * flourish
			elbow.x = -0.45 * flourish
		if not grounded or active_state in ["jump", "spring_release"]:
			var rise: float = clampf(-motion.y / 420.0, -1.0, 1.0)
			arm = Vector3(-0.85 - rise * 0.22, 0.0, sign_side * 0.35) * flourish
			elbow.x = -0.38 * flourish
			if active_state == "spring_release" and role == "bark":
				arm = Vector3(-0.18, 0.0, sign_side * 1.65) * flourish
		if active_state in ["delight", "celebrate", "cheer"]:
			arm = Vector3(-0.16, 0.0, sign_side * (1.95 + sin(age * 6.0 + sign_side) * 0.06 * still)) * flourish
			elbow.x = -0.45 * flourish
			wrist.y = sin(age * 5.0 + sign_side) * 0.12 * still
		elif active_state == "notebook":
			arm = Vector3(-0.80, sign_side * -0.10, -sign_side * 0.22)
			elbow = Vector3(-0.72, 0.0, -sign_side * 0.12)
			wrist = Vector3(0.14, sign_side * 0.08, 0.0)
		elif active_state in ["talk", "hint"]:
			arm.x = (-0.44 if side == "near" else -0.18) + sin(age * 3.1 + sign_side) * 0.12 * still
			arm.z = sign_side * (0.35 if active_state == "hint" else 0.16) * flourish
			elbow.x = -0.48 * flourish
			wrist.y = sin(age * 2.7) * 0.10 * still
		if active_state=="wave" and side=="far":
			arm=Vector3(-.25,0,1.85)*flourish
			elbow.x=-.65*flourish
			wrist.z=sin(state_age*12.0)*.32*still
		_rotate("shoulder_" + side, arm, delta, immediate)
		_rotate("elbow_" + side, elbow, delta, immediate)
		_rotate("wrist_" + side, wrist, delta, immediate)
		if grounded:
			if targets.has(side):
				_solve_leg(side, targets[side].point, float(targets[side].roll), hip_rotation.x)
		else:
			var rise: float = clampf(-motion.y / 420.0, -1.0, 1.0)
			_rotate("thigh_" + side, Vector3((-0.78 if role=="mark" else -0.55) - maxf(0.0, rise) * 0.22 + sign_side * 0.08, 0.0, sign_side * 0.05) * flourish, delta, immediate)
			_rotate("knee_" + side, Vector3((1.35 if role=="mark" else 1.05) + maxf(0.0, rise) * 0.20, 0.0, 0.0) * flourish, delta, immediate)
			_rotate("ankle_" + side, Vector3(-0.25, 0.0, 0.0) * flourish, delta, immediate)
			_rotate("toe_" + side, Vector3(-0.09, 0.0, 0.0) * flourish, delta, immediate)
	var follow: float = still * (0.08 if active_state in ["spring_contact", "spring_release"] else 0.035)
	_rotate("crown", Vector3(sin(age * 3.9 - 0.6) * follow, sin(age * 1.7) * 0.025 * still, 0.0), delta, immediate)
	_rotate("leaf_near", Vector3(sin(age * 4.7 - 0.8) * follow, sin(age * 3.2) * follow * 0.6, 0.0), delta, immediate)
	_rotate("leaf_far", Vector3(sin(age * 4.2 - 0.3) * follow, -sin(age * 3.6) * follow * 0.6, 0.0), delta, immediate)
	_rotate("coat", Vector3(-hip_rotation.x * 0.45 + sin(age * 3.2) * 0.02 * still, 0, sin(age * 2.8 - 0.4) * 0.025 * still), delta, immediate)
	if grounded:
		_pin_ground_contacts()
	_face(active_state)
	if model.has_method("set_pose_state") and active_state != _last_prop_state:
		model.call("set_pose_state", active_state)
		_last_prop_state = active_state
	applied_positions.clear()
	for key in joints:
		applied_positions[key] = joint_position(key)

func _solve_leg(side: String, target: Vector3, roll: float, body_angle: float) -> void:
	if not _legs.has(side):
		return
	var leg: Dictionary = _legs[side]
	var upper: Node3D = joints["thigh_" + side]
	var parent: Node3D = upper.get_parent()
	var parent_target: Vector3 = parent.to_local(model.to_global(target)) - upper.position
	var neutral: Basis = rest["thigh_" + side].basis
	var local: Vector3 = neutral.inverse() * parent_target
	var a: float = float(leg.upper)
	var b: float = float(leg.lower)
	var distance: float = clampf(Vector2(local.y, local.z).length(), absf(a - b) + 0.005, (a + b) * 0.998)
	var bend: float = acos(clampf((distance * distance - a * a - b * b) / (2.0 * a * b), -1.0, 1.0))
	var aim: float = atan2(-local.z, -local.y)
	var hip: float = aim - atan2(b * sin(bend), a + b * cos(bend)) - float(leg.upper_angle)
	var knee: float = bend - float(leg.knee_angle)
	_rotate("thigh_" + side, Vector3(hip, 0, 0), 0.0, true)
	_rotate("knee_" + side, Vector3(knee, 0, 0), 0.0, true)
	_rotate("ankle_" + side, Vector3(-hip - knee - body_angle + roll, 0, 0), 0.0, true)
	_rotate("toe_" + side, Vector3(0, 0, 0), 0.0, true)

func _pin_ground_contacts() -> void:
	if not joints.has("hips"):
		return
	var lowest: float = INF
	for side in _legs:
		var ankle: Node3D = joints["ankle_" + side]
		for point in _legs[side].contacts:
			lowest = minf(lowest, model.to_local(ankle.to_global(point)).y)
	if is_finite(lowest):
		joints.hips.position.y -= lowest

func _face(state: String) -> void:
	var still: float = 0.0 if reduced_motion else 1.0
	var phase: float = fposmod(age + (1.7 if role == "bark" else 0.7), 4.7)
	blink_value = sin(phase / 0.16 * PI) if phase < 0.16 and not reduced_motion else 0.0
	var talking: bool = state in ["talk", "hint"]
	mouth_open = (0.10 + maxf(0.0, sin(age * 11.0)) * 0.38) * still if talking else 0.0
	smile = 0.92 if state in ["delight", "celebrate", "cheer", "spring_release"] else 0.55
	brow = 0.36 if state in ["anticipate", "spring_contact", "hint"] else 0.15 if state == "notebook" else 0.0
	if state in ["delight", "celebrate", "cheer"]:
		mouth_open = 0.50 if reduced_motion else 0.52 + maxf(0.0, sin(state_age * 5.0)) * 0.10
		brow = 0.35
	gaze = Vector2(friend_direction*.65 if friend_left>0 else 0.0, 0.16 if state=="notebook" else 0.0)
	if state in ["hint","curious"]:brow=.5
	elif state=="wave":smile=.8;brow=.3
	if state in ["jump", "spring_release"]:
		blink_value = 0.0
		gaze.y = -0.12
	if model.has_method("set_emotion"):
		model.call("set_emotion",state)
	if model.has_method("set_expression"):
		model.call("set_expression", blink_value, gaze, mouth_open, smile, brow)

func look_at_friend(direction: float) -> void:
	friend_direction=signf(direction)
	friend_left=1.4
