extends "res://scripts/variety_platform.gd"

# The original chapter and climbing campaign share the bundled painted ledges.
# Width, impact feedback and the y=0 landing seam retain the original interface.
var height: float = 48.0

func _ready():
	if kind=="leaf":
		# Mossy garden branches belong to the original painted environment.
		atlas=Art.tex("school_props_log")
		region=Rect2(Vector2.ZERO,atlas.get_size())
		queue_redraw()
	else:
		super._ready()
