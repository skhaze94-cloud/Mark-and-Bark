extends Node2D
# Static storybook ornaments: one retained canvas, no timers, collision or input.
# Positioned in world coordinates, underneath gameplay and its existing prompts.
var foreground: bool = false
var tutorial: bool = false

func _draw() -> void:
	if foreground:
		if tutorial:
			_flower_border(0,1550)
		else:
			_flower_border(1700,2000)
	elif tutorial:
		_garden_whimsy(0,1550)
	else:
		_school_whimsy(0,1700)
		_garden_whimsy(1700,2000)
		_workshop_whimsy(3700,1900)

func paint_ellipse(at: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		points.append(at + Vector2(cos(i * TAU / 24.0),sin(i * TAU / 24.0)) * radius)
	draw_colored_polygon(points,color)

# Small, anchored illustrations decorate the borders of the original paintings.
# Their muted palette and placement keep discovery icons and landing areas clear.
func _leaf(at: Vector2, length: float, angle: float, ink: Color) -> void:
	var direction: Vector2 = Vector2.from_angle(angle)
	var normal: Vector2 = direction.orthogonal()
	var tip: Vector2 = at + direction * length
	var points: PackedVector2Array = PackedVector2Array([
		at, at + direction * length * .30 + normal * length * .28,
		at + direction * length * .75 + normal * length * .22, tip,
		at + direction * length * .70 - normal * length * .22,
		at + direction * length * .28 - normal * length * .19
	])
	draw_colored_polygon(points,ink)
	draw_line(at + direction * 2,tip - direction * 2,Color(.91,.91,.67,ink.a * .43),.8,true)

func _blossom(at: Vector2, size: float, ink: Color, seed: int = 0) -> void:
	# Irregular overlapping petals resemble pigment dabs rather than bright icons.
	for petal in range(5):
		var angle: float = float(petal) * TAU / 5.0 + float(seed) * .37
		var center: Vector2 = at + Vector2.from_angle(angle) * size * .56
		paint_ellipse(center,Vector2(size * .55,size * .46),ink.darkened(float(petal % 2) * .08))
	paint_ellipse(at + Vector2(.6,1),Vector2.ONE * size * .29,Color(.57,.42,.18,ink.a * .7))
	paint_ellipse(at - Vector2(.5,.7),Vector2.ONE * size * .23,Color(.99,.85,.46,ink.a))

func _star_charm(at: Vector2, size: float, ink: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(10):
		var radius: float = size if n % 2 == 0 else size * .43
		points.append(at + Vector2.from_angle(-PI * .5 + float(n) * PI / 5.0) * radius)
	draw_colored_polygon(points,ink)
	draw_line(at + Vector2(-size * .24,-size * .18),at + Vector2(0,-size * .65),Color(1,.96,.75,ink.a * .58),1,true)

func _garland(from: Vector2, to: Vector2, dip: float, botanical: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for n in range(33):
		var weight: float = float(n) / 32.0
		points.append(from.lerp(to,weight) + Vector2(0,sin(weight * PI) * dip))
	draw_polyline(points,Color(.27,.35,.28,.22),2,true)
	draw_polyline(points,Color(.84,.79,.58,.49),.9,true)
	for n in range(1,12):
		var weight: float = float(n) / 12.0
		var at: Vector2 = from.lerp(to,weight) + Vector2(0,sin(weight * PI) * dip)
		if botanical:
			_leaf(at,15 + n % 3 * 3,.55 if n % 2 == 0 else 2.3,Color(.38,.52,.35,.65))
			if n % 3 == 0:
				_blossom(at + Vector2(1,11),4.2,Color(.87,.76,.77,.76),n)
		else:
			var drop: float = 16 + n % 3 * 9
			draw_line(at,at + Vector2(0,drop),Color(.57,.48,.31,.43),1,true)
			var tip: Vector2 = at + Vector2(0,drop + 6)
			if n % 3 == 0:
				_star_charm(tip,6,Color(.89,.70,.40,.68))
			else:
				_leaf(tip,13,-.9 if n % 2 == 0 else .9,Color(.71,.77,.62,.76))

func _paper_bird(at: Vector2, scale_factor: float, direction: float) -> void:
	# Folded paper birds are part of a ceiling display, not collectible planes.
	draw_set_transform(at,direction,Vector2.ONE * scale_factor)
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-22,8),Vector2(-4,-15),Vector2(2,-2),Vector2(26,-6),Vector2(5,9),Vector2(-1,20),Vector2(-6,8)
	])
	draw_colored_polygon(outline,Color(.95,.87,.68,.79))
	draw_polygon(PackedVector2Array([Vector2(-22,8),Vector2(-4,-15),Vector2(-6,8)]),PackedColorArray([Color(.70,.75,.64,.57)]))
	draw_line(Vector2(-4,-15),Vector2(5,9),Color(.57,.55,.40,.49),1,true)
	draw_line(Vector2(-6,8),Vector2(26,-6),Color(1,.97,.81,.73),1,true)
	draw_set_transform(Vector2.ZERO)

func _school_whimsy(start: float, span: float) -> void:
	# Two quiet botanical swags dress the hallway's high wall, above the route.
	_garland(Vector2(start + 130,84),Vector2(start + 690,86),39,true)
	_garland(Vector2(start + span - 655,92),Vector2(start + span - 110,76),34,false)
	for n in range(3):
		var at: Vector2 = Vector2(start + 725 + n * 103,132 + n % 2 * 37)
		draw_line(at - Vector2(0,45 + n * 7),at,Color(.55,.49,.34,.33),1,true)
		_paper_bird(at,.62 + float(n) * .08,-.12 + float(n) * .11)

func _workshop_whimsy(start: float, span: float) -> void:
	# A little brass orrery hangs in the quiet wall area left of the live board.
	var origin: Vector2 = Vector2(start + span * .37,113)
	draw_line(origin - Vector2(0,75),origin,Color(.42,.38,.28,.51),1.4,true)
	draw_arc(origin,57,PI * .13,PI * .90,35,Color(.67,.52,.30,.65),1.7,true)
	draw_arc(origin + Vector2(0,4),57,PI * .13,PI * .90,35,Color(1,.89,.60,.30),1,true)
	for n in range(5):
		var relative: Vector2 = Vector2(-51 + n * 26,21 + sin(float(n) * .9) * 20)
		var length: float = 22 + float(posmod(n * 17,45))
		var at: Vector2 = origin + relative + Vector2(0,length)
		draw_line(origin + relative,at,Color(.46,.42,.30,.44),1,true)
		if n == 2:
			paint_ellipse(at,Vector2(11,11),Color(.78,.58,.30,.79))
			draw_arc(at,17,-.3,PI - .3,26,Color(.93,.78,.46,.69),1.6,true)
			draw_circle(at - Vector2(3,4),3,Color(1,.91,.61,.47))
		else:
			_star_charm(at,7 + n % 2 * 2,Color(.79,.70,.46,.72))
	# A small pressed-leaf swag unites the display with the painted foliage.
	_garland(Vector2(start + span * .58,102),Vector2(start + span * .88,117),22,true)

func _garden_whimsy(start: float, span: float) -> void:
	# Wisteria at the canopy edges catches light; the open middle stays readable.
	for side in range(2):
		var base: Vector2 = Vector2(start + 100 if side == 0 else start + span - 90,62)
		for branch in range(5):
			var root: Vector2 = base + Vector2((branch - 2) * 30,absf(float(branch - 2)) * 8)
			var length: float = 43 + float(posmod(branch * 29 + side * 23,65))
			draw_line(root,root + Vector2(8,length),Color(.35,.47,.28,.50),1.5,true)
			_leaf(root + Vector2(3,8),21,.5,Color(.39,.55,.32,.73))
			_leaf(root + Vector2(4,21),18,2.3,Color(.49,.62,.37,.70))
			for cluster in range(7):
				var weight: float = float(cluster) / 6.0
				var at: Vector2 = root + Vector2(5 + sin(float(cluster) * 1.8 + branch) * 3,24 + weight * length)
				var radius: float = 5.3 - weight * 3.4
				paint_ellipse(at + Vector2(-radius * .7,0),Vector2(radius,radius * .8),Color(.66,.61,.78,.59))
				paint_ellipse(at + Vector2(radius * .5,2),Vector2(radius,radius * .78),Color(.84,.77,.89,.66))
	# Small flowering patches sit below the world floor, never along jump ledges.
	for n in range(9):
		var at: Vector2 = Vector2(start + 75 + float(n) * (span - 150) / 8.0,690 + float(n % 3) * 8)
		for stem in range(3):
			var tip: Vector2 = at + Vector2(float(stem - 1) * 14,-21 - float(posmod(n * 11 + stem * 7,24)))
			draw_line(at,tip,Color(.34,.48,.28,.55),1.5,true)
			_leaf(at + (tip - at) * .45,10,-.8 if stem % 2 == 0 else 3.8,Color(.45,.59,.32,.67))
			_blossom(tip,4.4,Color(.93,.83,.61,.76) if n % 3 != 0 else Color(.80,.69,.81,.73),n + stem)

func _flower_border(start: float, span: float) -> void:
	# Foreground borders stay sparse and below the characters' feet.
	for side in range(2):
		var base: Vector2 = Vector2(start + 54 if side == 0 else start + span - 53,724)
		for stem in range(5):
			var tip: Vector2 = base + Vector2(float(stem - 2) * 15,-18 - float(posmod(stem * 13 + side * 19,24)))
			draw_line(base,tip,Color(.22,.37,.25,.72),2.4,true)
			_leaf(base + (tip - base) * .4,18,3.6 if stem % 2 == 0 else -.6,Color(.31,.47,.29,.78))
			_blossom(tip,5.8,Color(.94,.79,.58,.87) if stem % 2 == 0 else Color(.78,.68,.82,.82),stem)
