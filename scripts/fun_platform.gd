extends Node2D

# Painted ledges and collision share exactly the same top edge.
var width: float = 200.0
var kind: String = "book"
var height: float = 48.0
var reduced_motion: bool = false
var impact_age: float = 1.0
var force: float = 0.0

func impact(strength: float) -> void:
	impact_age=0
	force=strength
	queue_redraw()

func _process(delta: float) -> void:
	if impact_age<0.3:
		impact_age+=delta
		queue_redraw()

func _draw() -> void:
	var ink=Color("203849")
	for layer in range(4):
		draw_style_box(box(Color(0.08,0.13,0.13,0.045),Color.TRANSPARENT),Rect2(4+layer*2,6+layer*2,width,height))
	if kind=="pencil":
		draw_style_box(box(Color("d1a348"),ink),Rect2(0,0,width,height))
		draw_rect(Rect2(6,5,width-24,6),Color("f7df96"))
		draw_rect(Rect2(8,18,width-24,6),Color("b98636"))
		for x in range(12,int(width)-34,22):
			draw_line(Vector2(x,12),Vector2(x+13,13),Color(0.45,0.29,0.13,0.23),1)
		draw_line(Vector2(7,height-5),Vector2(width-27,height-5),Color("8d6230"),3)
		draw_rect(Rect2(width-26,2,22,height-4),Color("e2aa91"))
		draw_line(Vector2(width-31,2),Vector2(width-31,height-2),Color("e8e3d1"),7)
	elif kind=="leaf":
		var leaf=PackedVector2Array([Vector2(0,3),Vector2(width-10,3),Vector2(width,12),Vector2(width-15,height-5),Vector2(width*0.55,height+5),Vector2(16,height-7),Vector2(0,3)])
		draw_colored_polygon(leaf,Color("5d825a"))
		draw_polyline(leaf,ink,3)
		draw_line(Vector2(10,height-10),Vector2(width-16,height-12),Color("466345"),2)
		draw_line(Vector2(15,height-4),Vector2(width*0.55,height+1),Color("89a36d"),2)
		for x in range(21,int(width)-20,23):
			draw_circle(Vector2(x,18+(x%9)),0.8,Color(0.23,0.37,0.22,0.28))
		draw_line(Vector2(8,10),Vector2(width-10,10),Color("bacb83"),3)
		for x in range(25,int(width)-12,35):
			draw_line(Vector2(x,10),Vector2(x+15,height-6),Color("9cb77d"),2)
	else:
		draw_style_box(box(Color("46717a"),ink),Rect2(0,0,width,height))
		draw_rect(Rect2(10,10,width-20,height-19),Color("efdfb5"))
		for y in range(16,int(height)-10,5):
			draw_line(Vector2(14,y),Vector2(width-15,y),Color("c7b991"),1)
		draw_rect(Rect2(0,0,width,8),Color("d2ae58"))
		draw_rect(Rect2(0,height-7,width,7),Color("294e5c"))
		draw_line(Vector2(8,height-4),Vector2(width-8,height-4),Color("72949a"),1)
		# Rounded binding, corner gilding and a tiny ribbon give the book a finished edge.
		draw_style_box(box(Color("315963"),Color("203849")),Rect2(0,5,13,height-9))
		for x in [19.0,width-19.0]:
			draw_line(Vector2(x,4),Vector2(x+7,4),Color("fff1b4"),1)
		draw_colored_polygon(PackedVector2Array([Vector2(width-42,8),Vector2(width-31,8),Vector2(width-31,height+8),Vector2(width-36,height+3),Vector2(width-42,height+8)]),Color("b58150"))
	# Cream top seam and a small diamond mark make every landing readable.
	draw_line(Vector2(5,2),Vector2(width-5,2),Color("fff0bb"),3)
	var cx=width*0.5
	draw_colored_polygon(PackedVector2Array([Vector2(cx-5,0),Vector2(cx,-5),Vector2(cx+5,0),Vector2(cx,5)]),Color("fff0bb"))
	if impact_age<0.3 and not reduced_motion:
		var fade=(1-impact_age/0.3)*force
		draw_line(Vector2(9,1),Vector2(width-9,1),Color(1,0.91,0.61,fade*0.7),4,true)
		for side in [-1,1]:
			var at=Vector2(cx+side*(12+impact_age*55),-3-impact_age*16)
			draw_circle(at,2,Color(1,0.87,0.47,fade*0.65))

func box(fill: Color, edge: Color) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=fill
	s.border_color=edge
	s.set_border_width_all(2)
	s.set_corner_radius_all(7)
	return s
