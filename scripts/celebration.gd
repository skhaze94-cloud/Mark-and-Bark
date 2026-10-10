extends Control
var active: bool = false
var age: float = 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func begin() -> void:
	age=0
	active=true
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if not active:return
	age+=delta
	if age>7:
		active=false
		hide()
	queue_redraw()

func _draw() -> void:
	if not active:return
	var fade=clampf((7-age)/1.0,0,1)
	for i in range(30):
		# Confetti frames the ending panel; no piece travels across the text.
		var x: float=70+(i%6)*20 if i%2==0 else 1100+(i%6)*19
		var y: float=120+(i*67)%475
		var spin=0.0
		if not Progress.settings.reduced_motion:
			y=fmod(y+age*(27+i%5*4),650)
			x+=sin(age*1.2+i)*9
			spin=sin(age*1.1+i)*0.6
		var tint=Color("e2c475") if i%3==0 else Color("91ad80") if i%3==1 else Color("f3e4bb")
		tint.a=fade*0.85
		draw_set_transform(Vector2(x,y),spin)
		draw_colored_polygon(PackedVector2Array([Vector2(-5,0),Vector2(0,-7),Vector2(5,0),Vector2(0,7)]),tint)
		draw_line(Vector2(0,-5),Vector2(0,5),Color(0.2,0.32,0.25,fade*0.3),1)
		draw_set_transform(Vector2.ZERO)
