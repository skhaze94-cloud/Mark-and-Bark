extends Control
var value=0.0:
	set(v):
		value=clampf(v,0,100)
		queue_redraw()
func _draw():
	var track=StyleBoxFlat.new();track.bg_color=Color("43606b");track.set_corner_radius_all(4)
	draw_style_box(track,Rect2(Vector2.ZERO,size))
	if value>0:
		var fill=StyleBoxFlat.new();fill.bg_color=Color("d7b164");fill.set_corner_radius_all(4)
		draw_style_box(fill,Rect2(Vector2.ZERO,Vector2(size.x*value/100,size.y)))
