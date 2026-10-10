extends Node2D

# Painted ledges and collision share exactly the same top edge.
var width: float = 200.0
var kind: String = "book"
var height: float = 48.0

func _draw() -> void:
	var ink=Color("203849")
	draw_style_box(box(Color(0.08,0.13,0.13,0.20),Color.TRANSPARENT),Rect2(7,12,width,height))
	if kind=="pencil":
		draw_style_box(box(Color("d1a348"),ink),Rect2(0,0,width,height))
		draw_rect(Rect2(6,5,width-24,6),Color("f7df96"))
		draw_rect(Rect2(8,18,width-24,6),Color("b98636"))
		draw_rect(Rect2(width-26,2,22,height-4),Color("e2aa91"))
		draw_line(Vector2(width-31,2),Vector2(width-31,height-2),Color("e8e3d1"),7)
	elif kind=="leaf":
		var leaf=PackedVector2Array([Vector2(0,3),Vector2(width-10,3),Vector2(width,12),Vector2(width-15,height-5),Vector2(width*0.55,height+5),Vector2(16,height-7),Vector2(0,3)])
		draw_colored_polygon(leaf,Color("5d825a"))
		draw_polyline(leaf,ink,3)
		draw_line(Vector2(10,height-10),Vector2(width-16,height-12),Color("466345"),2)
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
	# Cream top seam and a small diamond mark make every landing readable.
	draw_line(Vector2(5,2),Vector2(width-5,2),Color("fff0bb"),3)
	var cx=width*0.5
	draw_colored_polygon(PackedVector2Array([Vector2(cx-5,0),Vector2(cx,-5),Vector2(cx+5,0),Vector2(cx,5)]),Color("fff0bb"))

func box(fill: Color, edge: Color) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=fill
	s.border_color=edge
	s.set_border_width_all(2)
	s.set_corner_radius_all(7)
	return s
