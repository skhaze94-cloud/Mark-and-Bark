extends Node2D
# Independent world-space contact shadows never inherit pickup bob or sprite scale.
var source: CanvasItem
var anchor: Vector2
var half_width: float = 28.0
var softness: float = 6.0
var opacity: float = 0.19
var follows: bool = false

func _process(_delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	visible=source.visible
	position=source.position if follows else anchor
	queue_redraw()

func _draw() -> void:
	for layer in range(4):
		var radius=Vector2(half_width*(1.0-layer*0.12),softness*(1.0-layer*0.14))
		var points=PackedVector2Array()
		for i in range(32):points.append(Vector2(7,3)+Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius)
		draw_colored_polygon(points,Color(0.08,0.12,0.12,opacity/4.0))
