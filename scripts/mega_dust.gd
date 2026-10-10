extends Node2D
var age=0.0
var reduced_motion=false
var refresh=0.0
func _process(delta):
	visible=not reduced_motion
	if reduced_motion:return
	age+=delta;refresh+=delta
	if refresh>.05:refresh=0;queue_redraw()
func _draw():
	for i in range(32):
		var x=100+fmod(i*137+sin(age*.35+i)*12,1400)
		var y=-2100+fmod(i*113+age*6,2750)
		draw_circle(Vector2(x,y),1.5,Color(1,.96,.8,.25))
