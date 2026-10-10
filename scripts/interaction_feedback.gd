extends Node2D
var campus
var focus_id: String = ""
var time: float = 0.0
var effects: Array[Dictionary] = []

func pulse(at: Vector2) -> void:
	effects.append({"at":at,"age":0.0})

func _process(delta: float) -> void:
	time+=delta
	for effect in effects:effect.age+=delta
	effects=effects.filter(func(e):return e.age<0.45)
	queue_redraw()

func _draw() -> void:
	var item: Dictionary=campus.object(focus_id)
	if not item.is_empty() and item.visible:
		var sprite: Sprite2D=item.sprite
		var rect: Rect2=sprite.get_rect()
		rect=Rect2(sprite.position+rect.position*sprite.scale,rect.size*sprite.scale).grow(8)
		var tint=Color(1.0,0.86,0.46,0.78)
		var length=minf(18.0,rect.size.x/4)
		for spec in [[rect.position,Vector2(1,1)],[Vector2(rect.end.x,rect.position.y),Vector2(-1,1)],[rect.end,Vector2(-1,-1)],[Vector2(rect.position.x,rect.end.y),Vector2(1,-1)]]:
			draw_line(spec[0],spec[0]+Vector2(spec[1].x*length,0),tint,2.2,true)
			draw_line(spec[0],spec[0]+Vector2(0,spec[1].y*length),tint,2.2,true)
		# The stable brackets identify the exact object, not just a nearby HUD label.
		var icon=Art.tex("ui_parts_hint_bulb")
		draw_texture_rect(icon,Rect2(rect.get_center().x-12,rect.position.y-32,24,24),false,Color(1,1,1,0.92))
	if not campus.reduced_motion:
		for effect in effects:
			var phase: float=effect.age/0.45
			draw_arc(effect.at,14+phase*28,0,TAU,32,Color(1,0.88,0.52,(1-phase)*0.5),2,true)
