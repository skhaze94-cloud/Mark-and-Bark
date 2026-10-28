extends Node2D
var home=Vector2.ZERO
var kind=0
var seed_phase=0.0
var age=0.0
var reduced_motion=false
var introduced=false
var last_draw=0.0
var skin: Texture2D
var eraser=Rect2()
func _ready():
	if ResourceLoader.exists("res://assets/variety/platform_atlas.png") and FileAccess.file_exists("res://assets/variety/regions.json"):
		skin=load("res://assets/variety/platform_atlas.png")
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/variety/regions.json"))
		if data is Dictionary and data.has("eraser"):
			var r=data.eraser;eraser=Rect2(r[0],r[1],r[2],r[3])
func tip():
	return ["Mark: Eraser beetles pace at the edge. Jump over their little feet.","Mark: Dust bunnies bob. Wait for one to settle, then leap past.","Mark: Paper moths fly in a small loop. Watch the gap, then spring through."][kind]
func advance(delta):
	age+=delta
	var t=age+seed_phase
	if kind==0:position=home+Vector2(sin(t*1.1)*12,0)
	elif kind==1:position=home+Vector2(sin(t*.9)*10,-maxf(0,sin(t*1.6))*22)
	else:position=home+Vector2(sin(t)*16,-15+sin(t*1.4)*18)
	if age-last_draw>.05:last_draw=age;queue_redraw()
func hit_box():return Rect2(position+Vector2(-17,-13),Vector2(34,27))
func _draw():
	var ink=Color("203849");var t=age+seed_phase
	draw_set_transform(Vector2(0,home.y-position.y+20),0,Vector2(1,.20));draw_circle(Vector2.ZERO,23,Color(.11,.16,.13,.16));draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	# Legible eyes, outlined silhouettes and ground marks avoid colour-only cues.
	if kind==0:
		for x in [-17,-6,6,17]:draw_line(Vector2(x,7),Vector2(x+(0 if reduced_motion else sin(t*5+x)*3),19),ink,3,true)
		draw_style_box(panel(Color("d59c88"),ink),Rect2(-24,-14,48,30))
		if skin!=null and eraser.size.x>0:draw_texture_rect_region(skin,Rect2(-24,-14,48,30),eraser)
		else:draw_rect(Rect2(-10,-13,20,28),Color("f1e5c3"));draw_line(Vector2(-6,-11),Vector2(-6,11),Color("638080"),3)
	elif kind==1:
		for n in range(8):draw_circle(Vector2(cos(n*TAU/8)*14,sin(n*TAU/8)*10),10,Color("a99f85"))
		draw_circle(Vector2(0,3),19,Color("bbae8e"));draw_circle(Vector2(-2,-2),17,Color("e1d6b7"));draw_arc(Vector2.ZERO,19,0,TAU,30,ink,2,true)
		draw_line(Vector2(-12,-15),Vector2(-15,-27),ink,2);draw_line(Vector2(12,-15),Vector2(15,-27),ink,2)
	else:
		var flap=0.0 if reduced_motion else sin(t*7)*5
		var wing=PackedVector2Array([Vector2(0,0),Vector2(-29,-19-flap),Vector2(-22,10),Vector2(0,6),Vector2(25,12),Vector2(31,-19+flap),Vector2(0,0)])
		draw_colored_polygon(wing,Color("e7dbb7"));draw_polyline(wing,ink,2,true)
		draw_line(Vector2(-27,-17-flap),Vector2(-6,1),Color("9a885f"),2);draw_line(Vector2(29,-17+flap),Vector2(6,1),Color("9a885f"),2)
		draw_circle(Vector2.ZERO,9,Color("6b8b70"))
	for x in [-7,7]:draw_circle(Vector2(x,-4),5,Color("fff4d7"));draw_circle(Vector2(x+1,-3),2.5,ink)
	draw_arc(Vector2(0,3),6,.15,PI-.15,12,ink,1.6,true)
	draw_line(Vector2(-27,24),Vector2(27,24),Color(.25,.30,.23,.3),2)
func panel(fill,edge):
	var s=StyleBoxFlat.new();s.bg_color=fill;s.border_color=edge;s.set_border_width_all(2);s.set_corner_radius_all(8);return s
