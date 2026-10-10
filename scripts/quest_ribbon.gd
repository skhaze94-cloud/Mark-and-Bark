extends Control
var step: int = 0
var total: int = 7
var previous: int = -1
var last_total: int = -1

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if previous!=step or last_total!=total:
		previous=step
		last_total=total
		queue_redraw()

func _draw() -> void:
	for i in range(total):
		var x=i*29.0
		var at=Vector2(x+8,8)
		if i<step:
			draw_circle(at,7,Color("e0bf72"))
			draw_line(at+Vector2(-3,0),at+Vector2(-1,3),Color("203849"),1.6,true)
			draw_line(at+Vector2(-1,3),at+Vector2(4,-3),Color("203849"),1.6,true)
		elif i==step:
			draw_circle(at,7,Color("fff2d2"),false,2,true)
			draw_circle(at,2,Color("fff2d2"))
		else:draw_circle(at,5,Color("80958b"),false,1,true)
		if i<total-1:draw_line(Vector2(x+18,8),Vector2(x+25,8),Color("80958b"),1,true)
