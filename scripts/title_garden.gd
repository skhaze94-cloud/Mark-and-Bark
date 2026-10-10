extends Node2D
var game
var time: float = 0.0

func _process(delta: float) -> void:
	time+=delta
	if game.mode!="title":return
	if not Progress.settings.reduced_motion:
		game.campus.bark.scale.y=0.31*(1+sin(time*1.7)*0.008)
	queue_redraw()

func _draw() -> void:
	# A little imagined flight above the duo, independent from all gameplay items.
	var points=PackedVector2Array()
	for i in range(22):
		var t=i/21.0
		points.append(Vector2(805+t*345,365-sin(t*PI)*78))
	for i in range(1,points.size()):
		if i%3!=0:draw_line(points[i-1],points[i],Color(1,0.90,0.64,0.72),2,true)
	var tilt=0.0 if Progress.settings.reduced_motion else sin(time*0.7)*0.03
	draw_set_transform(Vector2(1145,350),tilt)
	draw_texture_rect(Art.tex("collectibles_paper_plane"),Rect2(-60,-42,120,70),false)
	draw_set_transform(Vector2.ZERO)
