extends RefCounted
# One cached radial texture is shared by every room. No full-screen blur or HDR dependency.
static var soft_disc: GradientTexture2D

static func disc() -> GradientTexture2D:
	if soft_disc==null:
		var ramp=Gradient.new()
		ramp.offsets=PackedFloat32Array([0.0,0.35,1.0])
		ramp.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,.48),Color(1,1,1,0)])
		soft_disc=GradientTexture2D.new()
		soft_disc.gradient=ramp;soft_disc.width=128;soft_disc.height=128
		soft_disc.fill=GradientTexture2D.FILL_RADIAL
		soft_disc.fill_from=Vector2(.5,.5);soft_disc.fill_to=Vector2(1,.5)
	return soft_disc

static func glow(canvas: CanvasItem, at: Vector2, radius: Vector2, tint: Color) -> void:
	canvas.draw_texture_rect(disc(),Rect2(at-radius,radius*2.0),false,tint)

static func beam(canvas: CanvasItem, at: Vector2, width: float, reach: float, tint: Color) -> void:
	for layer in range(4):
		var feather=float(layer)*9.0
		var points=PackedVector2Array([at+Vector2(-feather,0),at+Vector2(width+feather,0),at+Vector2(width+reach*.55+feather,reach),at+Vector2(reach*.28-feather,reach)])
		var near=tint;near.a*=.19
		var far=tint;far.a*=.025
		canvas.draw_polygon(points,PackedColorArray([near,near,far,far]))
