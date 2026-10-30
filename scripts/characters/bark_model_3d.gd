extends Node3D
## Bark is a small living tree, built from actual tapered, curved 3D surfaces.
## Front is +Z, feet rest at Y=0. All performance pivots preserve this rest shape.
var joints: Dictionary = {}
var materials: Dictionary = {}
var built: bool = false
var _eye_lids: Array[Node3D] = []
var _pupils: Array[Node3D] = []
var _brows: Array[Node3D] = []
var _brow_rest: Array[Vector3] = []
var _mouth_open: Node3D
var _tongue: Node3D
var _smile_line: Node3D
var _surprised: Node3D
var _cheeks: Array[Node3D] = []
var emotion: String = "idle"
const Paint = preload("res://scripts/characters/painted_shapes_3d.gd")

func _ready() -> void:
	build()

func build() -> void:
	if built:
		return
	built = true
	# Broad living-tree presence, with a modest height increase over the painting.
	scale = Vector3(1.10,1.0,1.08)
	_materials()
	var hips = _joint("hips", self, Vector3(0, 0.44, 0))
	var spine = _joint("spine", hips, Vector3(0, 0.27, 0))
	# A single continuous trunk reaches down around the hips. There is no
	# separate pelvic bowl or visible waist hinge when the upper body leans.
	_trunk(spine, -0.32, 1.02, 0.13, 0.29, 0.76, 17)
	_chips(spine, -0.30, 0.98, 0.14, 0.29, 0.76, 86, 17)
	_bark_ridges(spine, -0.32, 1.01, 0.13, 0.29, 0.76, 6, 0)
	_bark_fringe(spine)
	var neck = _joint("neck", spine, Vector3(0, 0.61, 0.01))
	var head = _joint("head", neck, Vector3.ZERO)
	_trunk(head, -0.08, 0.56, 0.31, 0.32, 0.79, 43, true)
	_chips(head, -0.055, 0.54, 0.31, 0.32, 0.79, 40, 31, true)
	_bark_ridges(head, -0.06, 0.56, 0.31, 0.32, 0.79, 12, 1)
	_face(head)
	_crown(head)
	for side in [-1.0, 1.0]:
		_arm(spine, side)
		_leg(hips, side)
	set_expression(0, Vector2.ZERO, 0, 0.45, 0)
	var boundaries: Dictionary = {}
	for joint in joints.values():
		boundaries[joint.get_instance_id()] = true
	for item in _eye_lids + [_mouth_open,_tongue,_smile_line,_surprised]:
		boundaries[item.get_instance_id()] = true
	_batch_static(self,boundaries)

func _materials() -> void:
	materials.wood = _material(Color.WHITE, 0.92, true)
	materials.joint_wood = _material(Color("ad773e"),1.0)
	materials.groove = _material(Color("805027"), 0.94)
	materials.ridge = _material(Color("bf803c"), 0.88)
	materials.light_wood = _material(Color("d7a25c"), 0.9)
	materials.face = _material(Color("b88748"), 0.86)
	materials.brow = _material(Color("593b23"), 0.91)
	materials.cream = _material(Color("fff2c8"), 0.5)
	materials.iris = _material(Color("9a5c22"), 0.32)
	materials.pupil = _material(Color("201b14"), 0.22)
	materials.glint = _material(Color("fff8e2"), 0.18)
	materials.mouth = _material(Color("4a2c1d"), 0.96)
	materials.tongue = _material(Color("ba7254"), 0.85)
	materials.leaf = _material(Color.WHITE, 0.88, true)
	materials.leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials.vein = _material(Color("a0aa37"), 0.88)

func _material(tint: Color, roughness: float, vertex: bool = false) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.metallic = 0.0
	material.vertex_color_use_as_albedo = vertex
	material.vertex_color_is_srgb = vertex
	return material

func _joint(id: String, parent: Node3D, at: Vector3) -> Node3D:
	var node = Node3D.new()
	node.name = id
	node.position = at
	parent.add_child(node)
	joints[id] = node
	return node

func _mesh(parent: Node3D, geometry: Mesh, material: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = geometry
	instance.material_override = material
	instance.position = at
	instance.scale = scale_value
	parent.add_child(instance)
	return instance

func _ellipsoid(parent: Node3D, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 16
	return _mesh(parent, sphere, material, at, radii)

func _trunk(parent: Node3D, bottom: float, height: float, radius_bottom: float, radius_top: float, depth: float, seed: int, broken: bool = false) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 13
	var sides: int = 36
	var rows: Array = []
	for row in range(rings + 1):
		var t: float = float(row) / rings
		var ring: Array = []
		for n in range(sides):
			var angle: float = float(n) * TAU / sides
			var grain: float = sin(angle * 13.0 + t * 2.2 + seed) * 0.018 + sin(angle * 23.0 - t + seed) * 0.009
			var radius: float = lerpf(radius_bottom, radius_top, t) + sin(t * PI) * 0.025 + grain
			# The face occupies this sector: keep grain behind its painted surface.
			if broken and sin(angle)>.6 and t<.82:
				radius=minf(radius,.315)
			var top_cut: float = (sin(angle * 5.0 + seed) * 0.045 + cos(angle * 7.0) * 0.025) * pow(t, 12.0) if broken else 0.0
			var p = Vector3(cos(angle) * radius, bottom + height * t + top_cut, sin(angle) * radius * depth)
			p.x += sin(t * 2.8 + float(seed)) * 0.012
			var shade: float = 0.82 + 0.12 * sin(angle * 13.0 + t * 2.2 + seed) + 0.05 * sin(t * 17.0 + angle * 2.0)
			var color: Color = Color("b27736") * shade
			color.a = 1.0
			ring.append({"point": p, "normal": Vector3(cos(angle), -0.08, sin(angle) / depth).normalized(), "color": color})
		rows.append(ring)
	for row in range(rings):
		for side in range(sides):
			var next: int = (side + 1) % sides
			for corner in [[row,side],[row,next],[row+1,side],[row,next],[row+1,next],[row+1,side]]:
				var vertex: Dictionary = rows[corner[0]][corner[1]]
				st.set_normal(vertex.normal)
				st.set_color(vertex.color)
				st.add_vertex(vertex.point)
	# A real cross-cut rim and growth rings make the top read as woody volume.
	var top_y: float = bottom + height - 0.015
	for n in range(sides):
		var next: int = (n + 1) % sides
		for p in [Vector3(0, top_y - 0.025, 0), rows[rings][n].point, rows[rings][next].point]:
			st.set_normal(Vector3.UP)
			st.set_color(Color("91602d"))
			st.add_vertex(p)
	for n in range(sides):
		var next: int = (n + 1) % sides
		for p in [Vector3(0, bottom, 0), rows[0][next].point, rows[0][n].point]:
			st.set_normal(Vector3.DOWN)
			st.set_color(Color("8e5b2c"))
			st.add_vertex(p)
	_mesh(parent, st.commit(), materials.wood)
	if broken:
		for size_value in [0.53, 0.73]:
			var points: Array[Vector3] = []
			for n in range(25):
				var angle: float = float(n) * TAU / 24.0
				points.append(Vector3(cos(angle) * radius_top * size_value, top_y + 0.002, sin(angle) * radius_top * depth * size_value))
			_tube(parent, points, [0.006], materials.ridge, 5)

func _chips(parent: Node3D, bottom: float, height: float, radius_bottom: float, radius_top: float, depth: float, count: int, seed: int, face_gap: bool = false) -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for n in range(count):
		var t: float = (float(n % 7) + 0.4) / 7.8
		var angle: float = float(n) * 2.39996 + seed
		# Leave the facial panel smooth instead of putting grain over the eyes.
		if face_gap and sin(angle) > 0.55 and t > 0.11 and t < 0.80:
			continue
		var radius: float = lerpf(radius_bottom, radius_top, t) + 0.009
		var at = Vector3(cos(angle) * radius, bottom + height * t, sin(angle) * radius * depth)
		var basis = Basis.from_euler(Vector3(sin(angle) * -0.10, -angle + PI * 0.5, cos(angle) * 0.09))
		basis = basis.scaled(Vector3(0.013 + float(n % 3) * 0.006, 0.025 + float(n % 4) * 0.010, 0.009))
		transforms.append(Transform3D(basis, at))
		colors.append(Color("d29a50") if n % 3 != 0 else Color("8c572c"))
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = sphere
	multimesh.instance_count = transforms.size()
	for n in range(transforms.size()):
		multimesh.set_instance_transform(n, transforms[n])
		multimesh.set_instance_color(n, colors[n])
	var instance = MultiMeshInstance3D.new()
	instance.name = "RaisedBarkGrain"
	instance.multimesh = multimesh
	instance.material_override = materials.wood
	parent.add_child(instance)

func _bark_ridges(parent: Node3D, bottom: float, height: float, radius_bottom: float, radius_top: float, depth: float, count: int, skip_face: int) -> void:
	for n in range(count):
		var angle: float = float(n)*TAU/count + 0.13
		if skip_face == 1 and sin(angle)>0.50:
			continue
		var points: Array[Vector3] = []
		for row in range(7):
			var t: float = float(row)/6.0
			var bend: float = angle+sin(t*7.0+n)*0.065
			var radius: float = lerpf(radius_bottom,radius_top,t)+sin(t*PI)*0.025+0.007
			points.append(Vector3(cos(bend)*radius,bottom+height*t,sin(bend)*radius*depth))
		_tube(parent,points,[0.0045 if n%3 else 0.006],materials.groove if n%3 else materials.ridge,5)
	if skip_face == 0:
		for knot in [[-0.13,0.28],[0.12,0.48]]:
			var at: Vector3 = Vector3(knot[0],knot[1],0.252)
			_ellipsoid(parent,at,Vector3(0.026,0.044,0.015),materials.groove)
			var ring: Array[Vector3] = []
			for n in range(21):
				var theta: float = float(n)*TAU/20.0
				ring.append(at+Vector3(cos(theta)*0.038,sin(theta)*0.055,0.009))
			_tube(parent,ring,[0.007],materials.ridge,5)

func _bark_fringe(parent: Node3D) -> void:
	# Loose pointed bark bridges the flexible waist, like the source painting's
	# root-like bark hem. It moves with the spine rather than exposing a hinge.
	for n in range(9):
		var angle: float = float(n)*TAU/9.0
		var pivot = Node3D.new()
		pivot.position = Vector3(cos(angle)*0.145,-0.23,sin(angle)*0.145*0.76)
		pivot.rotation.y = PI*0.5-angle
		parent.add_child(pivot)
		var outline: Array[Vector2] = [Vector2(-0.018,0.10),Vector2(0.020,0.10),Vector2(0.022,-0.02),Vector2(0,-0.13-float(n%3)*0.016),Vector2(-0.019,-0.07)]
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for n_corner in range(outline.size()):
			var next: int = (n_corner+1)%outline.size()
			for point in [Vector2.ZERO,outline[n_corner],outline[next]]:
				st.set_normal(Vector3(0.08,0.02,1).normalized())
				st.set_color(Color("a87037") if n%3 else Color("ba8543"))
				st.add_vertex(Vector3(point.x,point.y,0.025 if point==Vector2.ZERO else 0.008))
		_mesh(pivot,st.commit(),materials.wood)

func _arm(spine: Node3D, side: float) -> void:
	var suffix: String="near" if side<0 else "far"
	var shoulder=_joint("shoulder_"+suffix,spine,Vector3(side*.25,.40,-.015))
	shoulder.rotation.z=side*.85
	_ellipsoid(shoulder,Vector3.ZERO,Vector3(.062,.068,.060),materials.joint_wood)
	_tube(shoulder,[Vector3.ZERO,Vector3(side*.025,-.085,.01),Vector3(side*.025,-.18,.025)],[.057,.045,.035],materials.wood,12,21)
	var elbow=_joint("elbow_"+suffix,shoulder,Vector3(side*.025,-.18,.025))
	elbow.rotation.z=side*.85
	_ellipsoid(elbow,Vector3.ZERO,Vector3(.043,.052,.043),materials.joint_wood)
	_tube(elbow,[Vector3.ZERO,Vector3(-side*.015,-.085,.04),Vector3(side*.015,-.16,.065)],[.036,.041,.033],materials.wood,12,11)
	var wrist=_joint("wrist_"+suffix,elbow,Vector3(side*.015,-.16,.065))
	_ellipsoid(wrist,Vector3.ZERO,Vector3(.040,.048,.041),materials.joint_wood)
	# Five long twig rays grow from a forked palm; no mitten-shaped hand mass.
	_tube(wrist,[Vector3(0,.02,0),Vector3(0,-.065,.015),Vector3(0,-.11,.02)],[.039,.046,.029],materials.wood,12,8)
	var tips=[Vector3(-.18,-.12,.025),Vector3(-.13,-.255,.035),Vector3(-.025,-.30,.035),Vector3(.09,-.265,.025),Vector3(.19,-.17,.015)]
	for finger in range(tips.size()):
		var tip: Vector3=tips[finger]
		var start=Vector3(tip.x*.18,-.055,.018)
		_tube(wrist,[start,Vector3(tip.x*.48,tip.y*.38,.045),Vector3(tip.x*.88,tip.y*.80,.06),tip+Vector3(-.008,0,.03)],[.032,.028,.021,.011],materials.wood,10,finger+7)
		_ellipsoid(wrist,tip,Vector3(.015,.020,.015),materials.ridge)
	var cluster=_joint("leaf_"+suffix,elbow,Vector3(side*.02,-.015,-.005))
	_leaf(cluster,Vector3.ZERO,Vector3(0,0,side*-.85),.16,.052,Color("77952b"))

func _leg(hips: Node3D, side: float) -> void:
	var suffix: String = "near" if side < 0 else "far"
	var thigh = _joint("thigh_"+suffix, hips, Vector3(side*0.12,-0.025,0))
	_tube(thigh,[Vector3.ZERO,Vector3(side*0.015,-0.12,0.015),Vector3(side*0.025,-0.20,0.035)],[0.095,0.085,0.07],materials.wood,11,4)
	var knee = _joint("knee_"+suffix, thigh, Vector3(side*0.025,-0.20,0.035))
	_ellipsoid(knee,Vector3.ZERO,Vector3(.080,.085,.080),materials.joint_wood)
	_tube(knee,[Vector3.ZERO,Vector3(side*.025,-.06,-.012),Vector3(side*.045,-.12,-.01),Vector3(side*.05,-.16,.015)],[.075,.081,.079,.080],materials.wood,12,7)
	var ankle = _joint("ankle_"+suffix, knee, Vector3(side*0.05,-0.16,0.015))
	_ellipsoid(ankle,Vector3.ZERO,Vector3(.083,.075,.083),materials.joint_wood)
	var toe = _joint("toe_"+suffix, ankle, Vector3(0,-0.025,0.075))
	_ellipsoid(toe,Vector3(0,0.030,0.025),Vector3(0.14,0.065,0.16),materials.ridge)
	for root in range(4):
		var across: float = (float(root)-1.5)*0.14
		if across*side<0:across*=.55
		_tube(toe,[Vector3(across*0.15,0.060,-0.025),Vector3(across*.70,0.025,0.11),Vector3(across*1.30,-0.003,0.215+float(root%2)*0.025)],[0.055,0.040,0.013],materials.wood,7,root+11)
		_tube(toe,[Vector3(across*.15,.103,-.025),Vector3(across*.70,.065,.11),Vector3(across*1.26,.007,.20)],[.0035,.0025,.001],materials.ridge,6)
	# The back root keeps the sole grounded from side and three-quarter views.
	_tube(ankle,[Vector3(0,0.02,0),Vector3(side*0.075,-0.012,-0.09),Vector3(side*0.12,-0.018,-0.16)],[0.045,0.031,0.010],materials.wood,7,5)

func _face(head: Node3D) -> void:
	# Painted almond eyes lie close to a warm, quiet facial panel.
	for paint in [materials.cream,materials.iris,materials.pupil,materials.glint,materials.brow,materials.mouth]:
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_ellipsoid(head,Vector3(0,0.16,0.244),Vector3(0.266,0.31,0.023),materials.face)
	for side in [-1.0,1.0]:
		var suffix: String = "near" if side < 0 else "far"
		var eye = _joint("eye_"+suffix,head,Vector3(side*0.135,0.255,0.267))
		eye.rotation.y=side*0.18
		Paint.almond(eye,Vector3.ZERO,Vector2(.094,.100),materials.brow)
		Paint.almond(eye,Vector3(0,-.003,.006),Vector2(.085,.089),materials.cream)
		var pupil = _joint("pupil_"+suffix,eye,Vector3(0,0,0.017))
		_ellipsoid(pupil,Vector3.ZERO,Vector3(0.058,0.070,0.004),materials.iris)
		_ellipsoid(pupil,Vector3(0,0.002,0.004),Vector3(0.034,0.052,0.003),materials.pupil)
		_ellipsoid(pupil,Vector3(-0.019,0.029,0.008),Vector3(0.014,0.018,0.002),materials.glint)
		_pupils.append(pupil)
		# Blink compresses the whole painted eye; no moving skin ball over it.
		_eye_lids.append(eye)
		var eyebrow = _joint("brow_"+suffix,head,Vector3(side*0.14,0.405,0.275))
		_tube(eyebrow,[Vector3(-0.09,0,0),Vector3(-0.035,0.023,0.006),Vector3(0.03,0.025,0.006),Vector3(0.09,0.006,0)],[0.015,0.018,0.016,0.008],materials.brow,8)
		_brows.append(eyebrow);_brow_rest.append(eyebrow.position)
	_ellipsoid(head,Vector3(0,0.115,0.281),Vector3(0.032,0.030,0.012),materials.light_wood)
	var mouth = _joint("mouth",head,Vector3(0,-0.018,0.267))
	# A generous warm grin is the defining shape in the original paintings.
	_mouth_open=Node3D.new();mouth.add_child(_mouth_open)
	Paint.grin(_mouth_open,Vector3.ZERO,.225,.175,materials.mouth)
	_tongue=_ellipsoid(_mouth_open,Vector3(0,-.125,.014),Vector3(.115,.030,.003),materials.tongue)
	var teeth=Paint.grin(_mouth_open,Vector3(0,.002,.012),.214,.047,materials.cream)
	for x in [-.095,-.032,.032,.095]:
		_tube(_mouth_open,[Vector3(x,-.027,.024),Vector3(x,.004,.024)],[.002],materials.iris,5)
	_surprised=Node3D.new();mouth.add_child(_surprised)
	_ellipsoid(_surprised,Vector3(0,-.035,.012),Vector3(.068,.078,.005),materials.mouth)
	for side in [-1.0,1.0]:
		var cheek=_joint("cheek_"+str(int(side)),head,Vector3(side*.235,.09,.253))
		_ellipsoid(cheek,Vector3.ZERO,Vector3(.040,.032,.008),materials.face);_cheeks.append(cheek)
	_smile_line=Node3D.new();mouth.add_child(_smile_line)
	var smile_points: Array[Vector3] = []
	for n in range(17):
		var t: float=float(n)/16.0*2.0-1.0
		smile_points.append(Vector3(t*.19,.038*t*t-.014+t*.009,.013-absf(t)*.008))
	_tube(_smile_line,smile_points,[.007],materials.mouth,6)

func _crown(head: Node3D) -> void:
	var crown = _joint("crown",head,Vector3(0,0.50,-0.015))
	for n in range(11):
		var angle: float = float(n)*TAU/11.0
		var at = Vector3(cos(angle)*0.24,0,sin(angle)*0.18)
		var reach: float = 0.08+float(n%5)*0.025
		_tube(crown,[at,at+Vector3(cos(angle)*0.025,reach*0.65,sin(angle)*0.025),at+Vector3(cos(angle)*0.018,reach,sin(angle)*0.018)],[0.024,0.015,0.005],materials.wood,8,n+4)
	for n in range(8):
		var side: float=-1 if n%2==0 else 1
		var at=Vector3(side*.275,-.08+float(n/2)*.06,-.09 if n<4 else .09)
		_leaf(crown,at,Vector3(.25,side*.2,-side*1.15),.16+float(n%3)*.02,.052,Color("6e8c29") if n%3 else Color("91a52e"))
	# Small shoots on the trunk sides retain the painted Bark silhouette.
	for side in [-1.0,1.0]:
		for n in range(2):
			var at = Vector3(side*(0.31-float(n)*0.015),-0.12+float(n)*0.20,-0.045)
			_tube(head,[at,at+Vector3(side*0.11,0.035,0),at+Vector3(side*0.14,0.07,0)],[0.022,0.014,0.006],materials.wood,7,n+8)
			_leaf(head,at+Vector3(side*0.12,0.045,0),Vector3(0.3,side*0.35,side*-1.0),0.15,0.052,Color("7c942a"))

func _leaf(parent: Node3D, at: Vector3, rotation_value: Vector3, length_value: float, width: float, tint: Color) -> void:
	var pivot = Node3D.new()
	pivot.position = at
	pivot.rotation = rotation_value
	parent.add_child(pivot)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var slices: int = 9
	var rows: Array = []
	for row in range(slices+1):
		var t: float = float(row)/slices
		var ring: Array[Vector3] = []
		for side in [-1.0,0.0,1.0]:
			ring.append(Vector3(side*sin(t*PI)*width,t*length_value,sin(t*PI)*0.025+(1.0-absf(side))*sin(t*PI)*0.018))
		rows.append(ring)
	for row in range(slices):
		for side in range(2):
			for corner in [[row,side],[row+1,side],[row,side+1],[row,side+1],[row+1,side],[row+1,side+1]]:
				var t: float = float(corner[0])/slices
				st.set_color(tint.lightened(0.12*(1.0-t)))
				st.add_vertex(rows[corner[0]][corner[1]])
	st.generate_normals()
	_mesh(pivot,st.commit(),materials.leaf)
	_tube(pivot,[Vector3(0,0,0.002),Vector3(0,length_value*0.5,0.047),Vector3(0,length_value,0.002)],[0.004,0.003,0.001],materials.vein,5)

func _tube(parent: Node3D, points: Array, radii: Array, material: Material, sides: int = 8, seed: int = 0) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for row in range(points.size()):
		var tangent: Vector3 = points[mini(row+1,points.size()-1)]-points[maxi(0,row-1)]
		tangent = tangent.normalized() if tangent.length_squared()>0.00001 else Vector3.UP
		var across: Vector3 = tangent.cross(Vector3.FORWARD).normalized()
		if across.length_squared()<0.001:
			across = tangent.cross(Vector3.RIGHT).normalized()
		var other: Vector3 = tangent.cross(across).normalized()
		var radius: float = float(radii[mini(row,radii.size()-1)])
		var ring: Array = []
		for n in range(sides):
			var angle: float = float(n)*TAU/sides
			var normal: Vector3 = across*cos(angle)+other*sin(angle)
			var grain: float = 1.0+0.045*sin(angle*5.0+seed)
			var tint: Color = Color("b67d3d")* (0.86+0.12*sin(angle*5.0+float(row)*0.3+seed))
			tint.a = 1
			ring.append({"point":points[row]+normal*radius*grain,"normal":normal,"color":tint})
		rows.append(ring)
	for row in range(points.size()-1):
		for side in range(sides):
			var next: int = (side+1)%sides
			for corner in [[row,side],[row+1,side],[row,next],[row,next],[row+1,side],[row+1,next]]:
				var vertex: Dictionary = rows[corner[0]][corner[1]]
				st.set_normal(vertex.normal)
				st.set_color(vertex.color)
				st.add_vertex(vertex.point)
	if points[0].distance_to(points[-1])>0.0001:
		for end in [0,points.size()-1]:
			for n in range(sides):
				var normal: Vector3 = (points[0]-points[1]).normalized() if end==0 else (points[-1]-points[-2]).normalized()
				var cap: Array = [points[end],rows[end][n].point,rows[end][(n+1)%sides].point] if end==0 else [points[end],rows[end][(n+1)%sides].point,rows[end][n].point]
				for point in cap:
					st.set_normal(normal)
					st.set_color(Color("a86e35"))
					st.add_vertex(point)
	return _mesh(parent,st.commit(),material)

func set_expression(blink: float, gaze: Vector2, mouth_open: float, smile: float, brow: float) -> void:
	if not built:return
	var delighted: bool=emotion in ["delight","celebrate","cheer","laugh"]
	var curious: bool=emotion in ["hint","curious","thinking","spot","point"]
	var surprise: bool=emotion=="surprise"
	var unsure: bool=emotion=="uncertain"
	for n in range(_eye_lids.size()):
		var height: float=.52 if delighted else 1.10 if surprise else .77 if curious else .86
		_eye_lids[n].scale.y=maxf(.04,(1-clampf(blink,0,1))*height)
		_pupils[n].position=Vector3(clampf(gaze.x,-1,1)*.012,clampf(gaze.y,-1,1)*.011,.017)
		var lift: float=.06 if surprise else (.04 if n==0 else -.005) if curious else .025 if delighted else .006
		_brows[n].position=_brow_rest[n]+Vector3(0,lift,0)
		_brows[n].rotation.z=(.27 if n==0 else -.06) if curious else (-.15 if n==0 else .15) if unsure else (.16 if n==0 else -.12) if delighted else (.055 if n==0 else -.015)
		_cheeks[n].position.y=.09+(.026 if delighted else 0)
	_surprised.visible=surprise
	_mouth_open.visible=not surprise and not unsure
	_smile_line.visible=unsure
	_mouth_open.scale=Vector3(1.05 if delighted else .94 if curious else 1.0,.95+mouth_open*.55 if delighted else .48+mouth_open*.6 if curious else .58,1)
	_tongue.visible=delighted or mouth_open>.2
	joints.mouth.rotation.z=-.055 if curious else .025

func _batch_static(anchor: Node3D, boundaries: Dictionary) -> void:
	var groups: Dictionary = {}
	_collect_static(anchor,Transform3D.IDENTITY,groups,boundaries)
	for group in groups.values():
		if group.size()<2:
			continue
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in group:
			var arrays: Array = part.node.mesh.surface_get_arrays(0)
			var colors = arrays[Mesh.ARRAY_COLOR]
			if colors == null or colors.size() == 0:
				var white = PackedColorArray()
				white.resize(arrays[Mesh.ARRAY_VERTEX].size())
				white.fill(Color.WHITE)
				arrays[Mesh.ARRAY_COLOR] = white
			var source = ArrayMesh.new()
			source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			surface.append_from(source,0,part.transform)
		var combined = _mesh(anchor,surface.commit(),group[0].node.material_override)
		combined.name = "SculptedBarkBatch"
		for part in group:
			part.node.get_parent().remove_child(part.node)
			part.node.free()

func _collect_static(branch: Node3D, relative: Transform3D, groups: Dictionary, boundaries: Dictionary) -> void:
	for child in branch.get_children():
		if child is MeshInstance3D:
			if boundaries.has(child.get_instance_id()) or child.mesh==null:
				continue
			var material: Material = child.material_override
			var key: int = material.get_instance_id() if material!=null else 0
			if not groups.has(key):
				groups[key] = []
			groups[key].append({"node":child,"transform":relative*child.transform})
		elif child is MultiMeshInstance3D:
			continue
		elif child is Node3D:
			if boundaries.has(child.get_instance_id()):
				_batch_static(child,boundaries)
			else:
				_collect_static(child,relative*child.transform,groups,boundaries)

func set_emotion(state: String) -> void:
	emotion=state
