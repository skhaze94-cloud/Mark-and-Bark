extends Node2D
# The source supplies visibility and a foot origin, never its animated transform.
# Fixed anchors and support_y are both expressed in the shadow parent's space.
var source: CanvasItem
var anchor: Vector2
var half_width: float = 28.0
var softness: float = 6.0
var opacity: float = 0.19
var follows: bool = false
var lift: float = 0.0
var _last_draw_state: Vector4 = Vector4(-1.0, -1.0, -1.0, -1.0)

func _ready() -> void:
	_sync_source()

func _process(_delta: float) -> void:
	_sync_source()

func _sync_source() -> void:
	if not is_instance_valid(source) or source.is_queued_for_deletion():
		queue_free()
		return
	visible = source.is_visible_in_tree()
	# A resting prop stays at the supplied anchor even when its art bobs or scales.
	position = anchor
	lift = 0.0
	var surface_owner := get_parent() as Node2D
	if follows and surface_owner != null and surface_owner.has_method("support_y"):
		# Resolve through world space: a nested source need not share our parent.
		var feet: Vector2 = surface_owner.to_local(source.get_global_transform().origin)
		var surface: float = float(surface_owner.call("support_y", feet.x, feet.y))
		position = Vector2(feet.x, surface)
		lift = maxf(0.0, surface - feet.y)
	var draw_state := Vector4(half_width, softness, opacity, lift)
	if draw_state != _last_draw_state:
		_last_draw_state = draw_state
		queue_redraw()

func _draw() -> void:
	var height_ratio := clampf(lift / 360.0, 0.0, 1.0)
	var footprint := lerpf(1.0, 0.52, height_ratio)
	var fade := lerpf(1.0, 0.22, height_ratio)
	var contact := clampf(1.0 - lift / 90.0, 0.0, 1.0)
	var radius := Vector2(maxf(half_width, 0.5), maxf(softness, 0.5)) * footprint
	var alpha := clampf(opacity, 0.0, 1.0) * fade
	# A quiet cast falls away from the shared upper-left room light.
	var cast_center := Vector2(radius.x * 0.20, radius.y * 0.70 + 0.5)
	for layer in range(3):
		var spread := 1.0 - float(layer) * 0.14
		_ellipse(cast_center, radius * Vector2(1.02, 0.86) * spread, alpha * (0.08 + float(layer) * 0.035))
	# Nested low-alpha contours form a soft penumbra with a stable foot center.
	for layer in range(5):
		var spread := 1.0 - float(layer) * 0.115
		_ellipse(Vector2(0.0, 1.0), radius * spread, alpha * (0.055 + float(layer) * 0.022))
	if contact > 0.0:
		_ellipse(Vector2(0.0, 0.6), radius * Vector2(0.48, 0.38), alpha * contact * 0.70)

func _ellipse(center: Vector2, radius: Vector2, alpha: float) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var angle := float(i) * TAU / 40.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.065, 0.09, 0.10, alpha))
