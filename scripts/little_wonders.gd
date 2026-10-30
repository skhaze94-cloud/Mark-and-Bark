extends Node2D
## Three optional, world-anchored miniature lives in the opening climb.
## No colliders, timers, tweens or per-frame node spawning; the game owns input.
const TITLES = ["Pencil Patrol", "Snail Mail", "Thimble Tea"]
const INVITATIONS = ["Help the tiny crossing", "Receive a tiny letter", "Join the tiny tea party"]
const LINES = ["Everyone gets right of way. Especially crumbs.", "Tea at the roof. Please bring your tallest friend.", "Bark: Finally. A cup in my size."]
const INK = Color("314c50")
const PAPER = Color("fff0cc")
var controller: Node
var entries: Array = []
var time: float = 0.0
var active: int = -1
var age: float = 0.0
var cooldown: float = 0.0
var nearby: int = -1
var reduced_motion: bool = false
var paused: bool = true
var revelations: int = 0

func configure(game: Node, shelves: Array[Rect2]) -> void:
	controller = game
	entries = [{"id":0, "at":Vector2(680,650)},
		{"id":1, "at":Vector2(shelves[9].position.x+120,shelves[9].position.y)},
		{"id":2, "at":Vector2(shelves[21].position.x+130,shelves[21].position.y)}]
	queue_redraw()

func discovered(id: int) -> bool:
	return id in Mega.runs[0].get("wonders", [])

func nearest() -> int:
	if not is_instance_valid(controller) or controller.busy or controller.mode != "campus" or controller.travelling:
		return -1
	if not controller.player.is_on_floor():
		return -1
	var best: int = -1
	var distance: float = 105.0
	for entry in entries:
		var offset: Vector2 = controller.player.position - entry.at
		if absf(offset.y) < 24.0 and absf(offset.x) < distance:
			best = int(entry.id)
			distance = absf(offset.x)
	return best

func can_interact() -> bool:
	return active < 0 and cooldown <= 0 and nearest() >= 0

func clear_companion_x(mark_at: Vector2, proposed: float) -> float:
	# Leave the little inhabitants visible when Bark settles beside his friend.
	for entry in entries:
		if absf(mark_at.y-entry.at.y)<12 and absf(mark_at.x-entry.at.x)<170 and absf(proposed-entry.at.x)<95:
			return mark_at.x+75*(1.0 if mark_at.x>=entry.at.x else -1.0)
	return proposed

func prompt() -> String:
	var id: int = nearest()
	return ("Visit " + TITLES[id] if discovered(id) else INVITATIONS[id]) if id >= 0 else ""

func interact() -> bool:
	if not can_interact():
		return false
	active = nearest()
	age = 0.0
	nearby = -1
	controller.campus.bark.pulse("wave",0.9)
	controller.player.sprite.pulse("hint",0.6)
	_friend_moment()
	controller.play_sound("collect", [0.88,1.04,1.18][active])
	if Progress.settings.reduced_motion:
		age = 6.0
		_complete()
	queue_redraw()
	return true

func _complete() -> void:
	if active < 0:
		return
	var visits: Array = Mega.runs[0].get("wonders", [])
	if not active in visits:
		visits.append(active)
		Mega.runs[0].wonders = visits
		Mega.save()
		revelations += 1
	controller.campus.bark.pulse("celebrate" if visits.size()==3 else "delight",0.7)
	controller.player.sprite.pulse("wave",.95)
	_friend_moment()
	active = -1
	cooldown = 3.0
	queue_redraw()

func notebook_text() -> String:
	var names: PackedStringArray = []
	for id in range(3):
		if discovered(id): names.append(TITLES[id])
	return "Little wonders: " + str(names.size()) + " / 3\n" + ("Three small lives are hiding in the library." if names.is_empty() else " · ".join(names))

func _process(delta: float) -> void:
	if not is_instance_valid(controller): return
	paused = controller.busy or controller.mode != "campus" or controller.travelling
	reduced_motion = bool(Progress.settings.reduced_motion)
	visible = controller.mode == "campus"
	if paused: return
	var step: float = minf(delta,0.1)
	cooldown = maxf(0,cooldown-step)
	nearby = nearest() if active < 0 and cooldown <= 0 else -1
	if not reduced_motion: time += step
	if active >= 0:
		age = 6.0 if reduced_motion else age+step
		if age >= 6.0: _complete()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(controller): return
	var frame: Rect2 = get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	for entry in entries:
		if not frame.grow(240).has_point(entry.at): continue
		draw_set_transform(entry.at)
		var id: int = int(entry.id)
		var playing: bool = active == id
		var phase: float = age if playing else 0.0
		var done: bool = discovered(id) or (playing and phase > 3.5)
		if id == 0: _crossing(phase,done,playing)
		elif id == 1: _post(phase,done,playing)
		else: _tea(phase,done,playing)
		if playing and (phase > 1.0 or reduced_motion): _bubble(LINES[id])
		elif nearby == id:
			_oval(Vector2(-70,-103),Vector2(12,12),INK)
			draw_string(Art.font,Vector2(-76,-97),"·" if controller.touch_mode or Progress.settings.touch else "E",HORIZONTAL_ALIGNMENT_LEFT,-1,16,PAPER)
			draw_string(Art.font,Vector2(-51,-97),"Use" if controller.touch_mode or Progress.settings.touch else "Say hello",HORIZONTAL_ALIGNMENT_LEFT,-1,15,PAPER)
	draw_set_transform(Vector2.ZERO)

func _oval(at: Vector2, radius: Vector2, ink: Color) -> void:
	var points: PackedVector2Array = []
	for n in range(36):
		var angle: float = TAU*float(n)/36.0
		points.append(at+Vector2(cos(angle),sin(angle))*radius)
	draw_colored_polygon(points,ink)

func _round(at: Vector2, radius: Vector2, ink: Color) -> void:
	# Soft pigment shading gives these tiny paper-and-felt folk rounded form.
	for n in range(16):
		var t: float = float(n)/15.0
		var centre: Vector2 = at+radius*Vector2(-0.23,-0.28)*t
		_oval(centre,radius*(1.0-t*0.73),ink.darkened(0.30).lerp(ink.lightened(0.16),smoothstep(0,1,t)))

func _shadow(at: Vector2, width: float) -> void:
	for n in range(4): _oval(at,Vector2(width-n*3,5-n*0.8),Color(0.12,0.18,0.15,0.035))

func _line(points: Array, ink: Color, width: float = 1.5) -> void:
	draw_polyline(PackedVector2Array(points),ink,width,true)

func _eye(at: Vector2, radius: float = 3.0) -> void:
	draw_circle(at+Vector2(0,0.7),radius+0.7,INK.lightened(0.05))
	draw_circle(at,radius,PAPER)
	draw_circle(at+Vector2(1,0),radius*0.58,INK)
	draw_circle(at+Vector2(0.3,-0.8),radius*0.20,Color.WHITE)

func _letter(at: Vector2, scale_factor: float = 1.0) -> void:
	var r = Rect2(at-Vector2(12,8)*scale_factor,Vector2(24,16)*scale_factor)
	draw_rect(r,Color("b68b57"))
	draw_rect(r.grow(-1.0),PAPER)
	_line([r.position,r.get_center(),Vector2(r.end.x,r.position.y)],Color("c6a374"),1)
	draw_circle(r.end-Vector2(4,4)*scale_factor,2*scale_factor,Color("c87b70"))

func _flower(at: Vector2, open: float = 1.0, pink: bool = false) -> void:
	_line([at+Vector2(0,19),at+Vector2(-2,8),at],Color("668b60"),2)
	for n in range(6):
		var angle: float = n*TAU/6.0
		_round(at+Vector2(cos(angle),sin(angle))*6*open,Vector2(4.5,4.5)*maxf(0.3,open),Color("e2a5ad") if pink else PAPER)
	draw_circle(at,3.6,Color("d9ad54"))

func _beetle(at: Vector2, phase: float, captain: bool = false, parcel: bool = false) -> void:
	_shadow(at+Vector2(0,1),24)
	for side in [-1,1]:
		for n in range(3):
			var x: float = -15+n*11
			var bounce: float = sin(phase*7+n*2)*2 if not reduced_motion else 0.0
			_line([at+Vector2(x,-10),at+Vector2(x+side*3,-3),at+Vector2(x+side*6+bounce,0)],INK,2)
	_round(at+Vector2(-4,-16),Vector2(23,14),Color("5f8b80") if captain else Color("bd8757"))
	_line([at+Vector2(-24,-19),at+Vector2(0,-13),at+Vector2(13,-19)],Color("365e5b"),1)
	for n in range(3): draw_circle(at+Vector2(-14+n*8,-22),2,Color("e8c66e"))
	_round(at+Vector2(20,-21),Vector2(11,10),Color("95744d"))
	_eye(at+Vector2(24,-25),3.4)
	_line([at+Vector2(26,-17),at+Vector2(29,-18)],INK)
	for n in [-1,1]:
		_line([at+Vector2(18+n*4,-28),at+Vector2(19+n*7,-38),at+Vector2(25+n*7,-39)],INK,1.5)
	if captain:
		_round(at+Vector2(18,-31),Vector2(14,4),Color("a65d59"))
		draw_rect(Rect2(at+Vector2(8,-41),Vector2(18,9)),Color("a65d59"))
		_oval(at+Vector2(17,-41),Vector2(9,3),Color("d28a77"))
	if parcel: _letter(at+Vector2(-5,-34),0.75)

func _crossing(phase: float, done: bool, playing: bool) -> void:
	_shadow(Vector2(25,2),82)
	# Painted pencil crossing: decorative markings leave the real route clear.
	for n in range(5): draw_rect(Rect2(28+n*13,-1,8,5),Color("f2d996"))
	_line([Vector2(-46,0),Vector2(-46,-58)],Color("977650"),4)
	_round(Vector2(-46,-53),Vector2(11,17),Color("ac8353"))
	_flower(Vector2(-46,-64),1.0 if done else lerpf(0.35,1.0,smoothstep(0.4,1.0,phase)) if playing else 0.35)
	_beetle(Vector2(-8,0),time,true)
	if playing and phase > 1.0 and phase < 5.5:
		var walk: float = smoothstep(1.0,5.5,phase)
		for n in range(3): _little_beetle(Vector2(lerpf(-30,130,walk)-n*34,3),phase,n==1)
	elif done:
		_little_beetle(Vector2(81,0),0,true)
	_line([Vector2(-62,-2),Vector2(-62,-18),Vector2(-36,-18),Vector2(-36,-2)],Color("b19165"),2)
	draw_rect(Rect2(-66,-28,36,13),INK)
	draw_string(Art.font,Vector2(-62,-18),"PATROL",HORIZONTAL_ALIGNMENT_LEFT,-1,8,PAPER)

func _little_beetle(at: Vector2, phase: float, parcel: bool) -> void:
	draw_set_transform(entries[0].at+at,0,Vector2.ONE*0.56)
	_beetle(Vector2.ZERO,phase,false,parcel)
	draw_set_transform(entries[0].at)

func _snail(at: Vector2, phase: float) -> void:
	_shadow(at,33)
	_round(at+Vector2(5,-7),Vector2(32,8),Color("a8b797"))
	_round(at+Vector2(-8,-25),Vector2(22,21),Color("c98d74"))
	var spiral: PackedVector2Array = []
	for n in range(65):
		var t: float = float(n)/64.0
		spiral.append(at+Vector2(-8,-26)+Vector2(cos(t*TAU*2),sin(t*TAU*2))*t*16)
	draw_polyline(spiral,Color("f2c595"),2.1,true)
	_round(at+Vector2(27,-15),Vector2(10,10),Color("a8b797"))
	for n in [0,1]:
		var sway: float = 0 if reduced_motion else sin(phase*1.5+n)*1.4
		var eye: Vector2 = at+Vector2(23+n*11+sway,-36)
		_line([at+Vector2(25+n*6,-20),eye],Color("71896b"),2.4)
		_eye(eye,3.5)
	_line([at+Vector2(29,-12),at+Vector2(34,-13)],INK)

func _post(phase: float, done: bool, playing: bool) -> void:
	_shadow(Vector2(-37,0),34)
	draw_rect(Rect2(-51,-39,7,38),Color("977650"))
	draw_style_box(_box(Color("557e7c"),9),Rect2(-69,-77,43,44))
	_oval(Vector2(-48,-76),Vector2(22,7),Color("779a8c"))
	_line([Vector2(-61,-60),Vector2(-36,-60)],INK,3)
	_letter(Vector2(-48,-48),0.6)
	_line([Vector2(-25,-60),Vector2(-25,-87),Vector2(-13,-87)],Color("ad6960"),3)
	_flower(Vector2(-61,-84),1.0,true)
	var drift: float = sin(time)*1.5 if not reduced_motion else 0.0
	_snail(Vector2(19+drift,-1),time)
	if playing:
		var t: float = smoothstep(1,4,phase)
		_letter(Vector2(lerpf(-48,44,t),-64-sin(t*PI)*27),1.0)
	elif done:
		_letter(Vector2(-10,-81),1.0)

func _bunny(at: Vector2, phase: float, tint: Color) -> void:
	_shadow(at,18)
	for n in range(9):
		var angle: float = float(n)*TAU/9
		_oval(at+Vector2(cos(angle)*13,-15+sin(angle)*12),Vector2(7,7),tint.darkened(0.08))
	_round(at+Vector2(0,-15),Vector2(17,17),tint)
	var wiggle: float = sin(phase*2.2)*2 if not reduced_motion else 0.0
	_round(at+Vector2(-7-wiggle,-38),Vector2(5,14),tint)
	_round(at+Vector2(7+wiggle,-36),Vector2(5,13),tint)
	_oval(at+Vector2(-7-wiggle,-39),Vector2(2,8),Color("d7a4a2"))
	_eye(at+Vector2(-6,-19),3)
	_eye(at+Vector2(5,-19),3)
	draw_circle(at+Vector2(0,-12),2.2,Color("b77f7d"))
	_line([at+Vector2(-3,-8),at+Vector2(0,-7),at+Vector2(4,-9)],INK,1)

func _cup(at: Vector2, tint: Color) -> void:
	draw_arc(at+Vector2(7,-5),4, -PI*0.5,PI*0.5,12,tint,2,true)
	_round(at+Vector2(0,-5),Vector2(7,7),tint)
	_oval(at+Vector2(0,-10),Vector2(6,2.5),Color("745f52"))
	_oval(at+Vector2(-1,-11),Vector2(4,1),Color("b29470"))

func _tea(phase: float, done: bool, playing: bool) -> void:
	_shadow(Vector2(0,1),71)
	_oval(Vector2(1,1),Vector2(75,9),Color("bba68a"))
	_oval(Vector2(1,-1),Vector2(72,7),Color("dec2b7"))
	_bunny(Vector2(-52,-2),time,Color("d8d5c4"))
	_bunny(Vector2(52,-2),time+1.2,Color("ccc8cb"))
	draw_rect(Rect2(-17,-21,34,19),Color("ac8d68"))
	for x in range(-12,17,6): draw_line(Vector2(x,-20),Vector2(x,-3),Color("d6b892"),1,true)
	_oval(Vector2(0,-24),Vector2(35,10),Color("896f59"))
	_oval(Vector2(0,-27),Vector2(35,10),PAPER)
	var lift: float = sin(clampf((phase-1.5)/3.0,0,1)*PI)*12 if playing else 0.0
	_cup(Vector2(-27,-29-lift),Color("719c8e"))
	_cup(Vector2(27,-29-lift),Color("cf9a98"))
	_round(Vector2(0,-40),Vector2(12,14),Color("a897b3"))
	draw_arc(Vector2(-12,-41),7,PI*0.45,PI*1.6,16,Color("a897b3"),3,true)
	_line([Vector2(9,-39),Vector2(17,-43),Vector2(20,-52)],Color("a897b3"),5)
	_oval(Vector2(0,-52),Vector2(12,3),Color("c8b7d0"))
	draw_circle(Vector2(0,-57),3,Color("d6b96e"))
	for n in range(2):
		var wave: float = 0 if reduced_motion else sin(time*1.5+n)*2
		_line([Vector2(-5+n*9,-59),Vector2(-8+n*9+wave,-66),Vector2(-4+n*9,-74)],Color(0.93,0.91,0.81,0.65),1.3)
	_line([Vector2(73,-3),Vector2(73,-85)],Color("b18e60"),2)
	var canopy: float = 1 if done else 0.7
	var parasol: PackedVector2Array = [Vector2(73,-97),Vector2(73+39*canopy,-77)]
	for n in range(13):
		var t: float = float(n)/12.0
		parasol.append(Vector2(73+lerpf(39,-39,t)*canopy,-77-sin(t*PI)*7))
	draw_colored_polygon(parasol,Color("91ad95"))
	for n in range(5): _line([Vector2(73,-97),Vector2(73+(n-2)*19*canopy,-77)],Color("c4d0a4"),1)
	if done: _flower(Vector2(-80,-17),1.0,true)
	if playing and phase>2 and not reduced_motion:
		for n in range(5):
			var angle: float = float(n)*TAU/5+phase*0.5
			var at: Vector2 = Vector2(cos(angle)*48,-62+sin(angle)*18)
			draw_circle(at,2,Color("e2bf6f"))

func _box(tint: Color, radius: int) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = tint
	box.border_color = tint.darkened(0.3)
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _bubble(words: String) -> void:
	var rect = Rect2(-152,-199,294,57)
	draw_style_box(_box(PAPER,13),rect)
	draw_colored_polygon(PackedVector2Array([Vector2(-17,-143),Vector2(-7,-134),Vector2(0,-143)]),PAPER)
	var font: Font = Art.font
	var lines: PackedStringArray = []
	var line: String = ""
	for word in words.split(" "):
		if font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x>264:
			lines.append(line);line=""
		line+=word+" "
	lines.append(line)
	for n in range(mini(2,lines.size())):
		draw_string(font,rect.position+Vector2(14,22+n*19),lines[n],HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)

func _friend_moment() -> void:
	var mark=controller.player.sprite
	var bark=controller.campus.bark
	var direction=signf(bark.global_position.x-mark.global_position.x)
	if direction==0:direction=1.0
	# Convert world direction to each painted actor's local facing.
	mark.character3d.greet_friend(direction*signf(mark.scale.x))
	bark.character3d.greet_friend(-direction*signf(bark.scale.x))
