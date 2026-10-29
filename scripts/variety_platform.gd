extends Node2D
# The atlas top and the independent collision surface share local y=0.
var library_style: bool = false
var width: float = 260.0
var kind: String = "book"
var reduced_motion: bool = false
var impact_age: float = 1.0
var force: float = 0.0
var atlas: Texture2D
var region := Rect2()

func _ready() -> void:
	if ResourceLoader.exists("res://assets/variety/platform_atlas.png"):
		atlas = load("res://assets/variety/platform_atlas.png")
	var regions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/variety/regions.json"))
	if regions is Dictionary:
		var r: Variant = regions.get(kind, regions.get("book", []))
		if r is Array and r.size() == 4:
			region = Rect2(r[0], r[1], r[2], r[3])
	queue_redraw()

func impact(strength: float) -> void:
	impact_age = 0.0
	force = strength
	queue_redraw()

func _process(delta: float) -> void:
	if impact_age < 0.3:
		impact_age += delta
		queue_redraw()

func _draw() -> void:
	var has_atlas := atlas != null and region.size.x > 0.0
	var depth: float = region.size.y * width / region.size.x if has_atlas else 38.0
	_draw_cast_shadow(depth, has_atlas)
	if has_atlas:
		draw_texture_rect_region(atlas, Rect2(0.0, 0.0, width, depth), region)
	else:
		draw_rect(Rect2(0.0, 0.0, width, depth), Color("8c7150"))
	# The cream seam stays on the playable top; shadows never move the artwork.
	draw_line(Vector2(12.0, 2.0), Vector2(width - 12.0, 2.0), Color("fff0bb"), 2.0, true)
	var x := width * 0.5
	draw_colored_polygon(PackedVector2Array([Vector2(x - 4.0, 0.0), Vector2(x, -5.0), Vector2(x + 4.0, 0.0), Vector2(x, 4.0)]), Color("fff0bb"))
	if impact_age < 0.3 and not reduced_motion:
		draw_line(Vector2(12.0, 2.0), Vector2(width - 12.0, 2.0), Color(1.0, 0.91, 0.61, (1.0 - impact_age / 0.3) * force * 0.65), 4.0, true)

func _draw_cast_shadow(depth: float, has_atlas: bool) -> void:
	# Every room gets the same light direction; the library's recess is deeper.
	var strength: float = 0.25 if library_style else 0.20
	for layer in range(5):
		var spread := float(4 - layer)
		var offset := Vector2(4.0 + spread * 0.9, 5.0 + spread * 0.85)
		var shadow_rect := Rect2(offset - Vector2(spread * 0.5, spread * 0.25), Vector2(width + spread, depth + spread * 0.5))
		var tint := Color(0.075, 0.085, 0.075, strength * (0.10 + float(layer) * 0.05))
		if has_atlas:
			draw_texture_rect_region(atlas, shadow_rect, region, tint)
		else:
			draw_rect(shadow_rect, tint)
	# A small occlusion band gives the underside weight without a hard black box.
	for layer in range(3):
		var inset := 8.0 + float(layer) * 2.0
		draw_line(Vector2(inset, depth + 1.0 + float(layer) * 1.5), Vector2(width - inset + 3.0, depth + 1.0 + float(layer) * 1.5), Color(0.075, 0.085, 0.075, strength * 0.16), 3.0 - float(layer) * 0.5, true)
