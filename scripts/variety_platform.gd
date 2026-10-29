extends Node2D
# The atlas top and the independent collision surface share local y=0.
var library_style=false
var width=260.0
var kind="book"
var reduced_motion=false
var impact_age=1.0
var force=0.0
var atlas: Texture2D
var region=Rect2()
func _ready():
	if ResourceLoader.exists("res://assets/variety/platform_atlas.png"):atlas=load("res://assets/variety/platform_atlas.png")
	var regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/variety/regions.json"))
	if regions is Dictionary:
		var r=regions.get(kind,regions.book);region=Rect2(r[0],r[1],r[2],r[3])
	queue_redraw()
func impact(strength):impact_age=0;force=strength;queue_redraw()
func _process(delta):
	if impact_age<.3:impact_age+=delta;queue_redraw()
func _draw():
	if atlas==null or region.size.x<=0:
		draw_rect(Rect2(0,0,width,38),Color("8c7150"));draw_line(Vector2.ZERO,Vector2(width,0),Color("fff0bb"),3);return
	var depth=region.size.y*width/region.size.x
	for n in range(3):draw_rect(Rect2(5+n*2,depth-4+n*2,width-10,5),Color(.12,.13,.11,.045))
	if library_style:
		# A soft cast shadow separates painted props from the recessed book wall.
		draw_texture_rect_region(atlas,Rect2(4,6,width,depth),region,Color(.12,.10,.07,.22))
	draw_texture_rect_region(atlas,Rect2(0,0,width,depth),region)
	draw_line(Vector2(12,2),Vector2(width-12,2),Color("fff0bb"),2,true)
	var x=width*.5;draw_colored_polygon(PackedVector2Array([Vector2(x-4,0),Vector2(x,-5),Vector2(x+4,0),Vector2(x,4)]),Color("fff0bb"))
	if impact_age<.3 and not reduced_motion:draw_line(Vector2(12,2),Vector2(width-12,2),Color(1,.91,.61,(1-impact_age/.3)*force*.65),4,true)
