extends Node2D
# One mounted live chalkboard: assembly, flight settings and fair delivery target.
var angle: int = 1
var power: int = 0
var frame: Sprite2D
var heading: Label
var status: Label
var time: float = 0.0
const TARGET = Vector2(130,-95)

func _ready() -> void:
	frame=Art.prop("invention_board_v3",540)
	frame.position=Vector2.ZERO
	frame.show_behind_parent=true
	var cast=Sprite2D.new()
	cast.texture=frame.texture
	cast.centered=false
	cast.offset=frame.offset
	cast.position=Vector2(20,15)
	cast.modulate=Color(0.08,0.12,0.12,0.20)
	cast.show_behind_parent=true
	frame.add_child(cast)
	add_child(frame)
	# The frame keeps its oak detail; live drawings replace its baked chalk doodles.
	var slate=Polygon2D.new()
	slate.polygon=PackedVector2Array([Vector2(-235,-248),Vector2(237,-248),Vector2(237,-63),Vector2(-235,-63)])
	slate.color=Color.WHITE
	slate.texture=Art.tex("invention_board_v3")
	slate.uv=PackedVector2Array([Vector2(600,350),Vector2(950,350),Vector2(950,550),Vector2(600,550)])
	slate.show_behind_parent=true
	add_child(slate)
	heading=make_label("OUR BIG IDEA",Vector2(-225,-241),18,Color("f1e7c8"))
	status=make_label("",Vector2(-225,-87),15,Color("d6e7d5"))
	z_index=1

func make_label(text: String, at: Vector2, size: int, colour: Color) -> Label:
	var label=Label.new()
	label.text=text
	label.position=at
	label.size=Vector2(440,30)
	label.add_theme_font_override("font",Art.font)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",colour)
	add_child(label)
	return label

func _process(delta: float) -> void:
	time+=delta
	var built=int(Progress.data.assembled)
	status.text="Invitation delivered!" if Progress.data.completed else "Build: "+str(built)+" / 3  ·  Angle "+str([25,40,55][angle])+"°  ·  "+["Gentle","Medium","Strong"][power]
	queue_redraw()

func _draw() -> void:
	var chalk=Color("e2ead7")
	var built=int(Progress.data.assembled)
	for i in range(3):
		var at=Vector2(-184+i*75,-161)
		var icon=Art.tex(["collectibles_books","collectibles_pencil","collectibles_paper_plane"][i])
		draw_texture_rect(icon,Rect2(at-Vector2(24,24),Vector2(48,48)),false,Color(1,1,1,1 if i<built else 0.32))
		if i<built:
			draw_line(at+Vector2(-10,32),at+Vector2(-3,38),chalk,2,true)
			draw_line(at+Vector2(-3,38),at+Vector2(12,23),chalk,2,true)
		else:draw_circle(at+Vector2(0,33),6,Color(0.85,0.9,0.8,0.5),false,1.5,true)
	# A small chalk diagram reacts to chosen presets; the playable target stays fixed.
	var previous=Vector2(12,-135)
	for i in range(1,20):
		var t=float(i)/19.0
		var next=Vector2(12+t*(100+power*22),-135-sin(t*PI)*(22+angle*13)+t*30)
		if i%3!=0:draw_line(previous,next,Color(0.89,0.87,0.68,0.75),1.4,true)
		previous=next
	# Actual target centre is exactly the existing 5050,290 quest coordinate.
	draw_circle(TARGET,36,Color("efe5bc"))
	draw_circle(TARGET,30,Color("466367"))
	draw_circle(TARGET,21,Color("e0bd67"),false,2,true)
	var envelope=Art.tex("collectibles_envelope")
	draw_texture_rect(envelope,Rect2(TARGET-Vector2(17,13),Vector2(34,26)),false)
	if Progress.data.completed:
		draw_line(TARGET+Vector2(-13,0),TARGET+Vector2(-3,10),chalk,4,true)
		draw_line(TARGET+Vector2(-3,10),TARGET+Vector2(17,-14),chalk,4,true)
