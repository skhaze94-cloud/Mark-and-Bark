extends Node3D
## Mark's actual volumetric storybook model. Feet at y0, front +Z.
## Every limb has a real pivot; static sculptural pieces batch per material/joint.
var joints: Dictionary = {}
var face: Dictionary = {}
var model_height: float = 2.43
var _built: bool = false
var _materials: Dictionary = {}
var _eye_rest: Dictionary = {}
var _brow_rest: Dictionary = {}
var props: Dictionary = {}
var emotion: String = "idle"
var hands: Dictionary = {}
const Paint = preload("res://scripts/characters/painted_shapes_3d.gd")

func _ready() -> void:
	build()

func build() -> void:
	if _built:
		return
	_built = true
	# A little shoulder and torso breadth gives the child a solid silhouette.
	scale = Vector3(1.12, 1.0, 1.06)
	var hips = _joint("hips", self, Vector3(0, 0.895, 0))
	var spine = _joint("spine", hips, Vector3(0, 0.40, 0))
	var neck = _joint("neck", spine, Vector3(0, 0.40, 0))
	var head = _joint("head", neck, Vector3(0, 0.28, 0.015))
	head.scale = Vector3(.99,1.12,1.04)
	var coat = _joint("coat", spine, Vector3.ZERO)
	var crown = _joint("crown", head, Vector3(0, 0.20, 0))
	_build_body(spine, coat, neck, hips)
	_build_head(head, crown)
	for side in ["near", "far"]:
		_build_arm(spine, side)
		_build_leg(hips, side)
	_build_notebook()
	_batch_static(self)
	set_expression(0, Vector2.ZERO, 0, 0.65, 0)

func _joint(key: String, parent: Node3D, at: Vector3) -> Node3D:
	var pivot = Node3D.new()
	pivot.name = key
	pivot.position = at
	parent.add_child(pivot)
	joints[key] = pivot
	return pivot

func _mat(key: String, colour: String, roughness: float = 0.88) -> StandardMaterial3D:
	if not _materials.has(key):
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(colour)
		material.roughness = 1.0
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_BACK
		_materials[key] = material
	return _materials[key]

func _mesh(parent: Node3D, geometry: Mesh, material: Material, at: Vector3 = Vector3.ZERO, scaling: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = geometry
	part.material_override = material
	part.position = at
	part.scale = scaling
	parent.add_child(part)
	return part

func _oval(parent: Node3D, at: Vector3, radius: Vector3, material: Material) -> MeshInstance3D:
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 12
	return _mesh(parent, sphere, material, at, radius)

func _tube(parent: Node3D, points: Array, radius: float, material: Material, taper: float = 1.0) -> void:
	for n in range(points.size() - 1):
		var a: Vector3 = points[n]
		var b: Vector3 = points[n + 1]
		var segment = CylinderMesh.new()
		segment.top_radius = radius * lerpf(1, taper, float(n + 1) / float(points.size() - 1))
		segment.bottom_radius = radius * lerpf(1, taper, float(n) / float(points.size() - 1))
		segment.height = a.distance_to(b)
		segment.radial_segments = 8
		segment.rings = 1
		var part = _mesh(parent, segment, material, (a + b) * 0.5)
		part.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _loft(parent: Node3D, rings: Array, material: Material, segments: int = 28) -> MeshInstance3D:
	# Smooth radius transitions keep cloth and limbs from becoming straight prisms.
	var smooth_rings=[]
	for row in range(rings.size()-1):
		var a: Vector4=rings[maxi(0,row-1)];var b: Vector4=rings[row]
		var c: Vector4=rings[row+1];var d: Vector4=rings[mini(rings.size()-1,row+2)]
		for step in range(3):
			var t: float=float(step)/3.0
			var v: Vector4=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
			v.x=lerpf(b.x,c.x,t);v.y=maxf(.001,v.y);v.z=maxf(.001,v.z);smooth_rings.append(v)
	smooth_rings.append(rings[-1]);rings=smooth_rings
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colours = PackedColorArray()
	var indices = PackedInt32Array()
	for row in range(rings.size()):
		var ring: Vector4 = rings[row]
		var before: Vector4 = rings[maxi(0, row - 1)]
		var after: Vector4 = rings[mini(rings.size() - 1, row + 1)]
		var dy: float = maxf(0.001, after.x - before.x)
		for n in range(segments + 1):
			var angle: float = float(n) * TAU / float(segments)
			var ca: float = cos(angle)
			var sa: float = sin(angle)
			vertices.append(Vector3(ca * ring.y, ring.x, sa * ring.z + ring.w))
			var along = Vector3(ca * (after.y - before.y) / dy, 1, sa * (after.z - before.z) / dy + (after.w - before.w) / dy)
			var tangent = Vector3(-sa * ring.y, 0, ca * ring.z)
			normals.append(along.cross(tangent).normalized())
			var pigment: float = 0.965 + sin(angle * 5.0 + float(row) * 2.3) * 0.025
			colours.append(Color(pigment, pigment, pigment, 1))
	for row in range(rings.size() - 1):
		for n in range(segments):
			var index: int = row * (segments + 1) + n
			indices.append_array(PackedInt32Array([index, index + 1, index + segments + 1, index + 1, index + segments + 2, index + segments + 1]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var geometry = ArrayMesh.new()
	geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh(parent, geometry, material)

func _build_body(spine: Node3D, coat: Node3D, neck: Node3D, hips: Node3D) -> void:
	var jacket = _mat("jacket", "2e4d6b")
	var blue_light = _mat("jacket_light", "52778d")
	var blue_dark = _mat("jacket_dark", "1a3048")
	var denim = _mat("denim", "3c5a70")
	var ochre = _mat("shirt", "e5ad38")
	var gold_light = _mat("shirt_light", "f3c862")
	var seam = _mat("jacket_seam", "718694")
	var cord = _mat("cord", "d5c7a9")
	var zip = _mat("zip", "b6a27b", 0.55)
	_loft(coat, [Vector4(-0.28,0.245,0.15,0),Vector4(-0.25,0.28,0.17,0),Vector4(-0.08,0.26,0.19,0),Vector4(0.14,0.27,0.185,0),Vector4(0.24,0.27,0.16,-0.01),Vector4(0.31,0.20,0.13,0),Vector4(0.34,0.10,0.085,0)], jacket)
	_loft(hips, [Vector4(-0.05,0.22,0.14,0),Vector4(0.0,0.25,0.155,0),Vector4(0.12,0.24,0.15,0)], denim)
	# The tee is a curved front panel, wrapped onto the jacket's volume.
	_front_panel(coat, [Vector3(-0.27,0.115,0.175),Vector3(-0.10,0.12,0.199),Vector3(0.12,0.135,0.198),Vector3(0.29,0.115,0.157)], ochre)
	_tube(coat, [Vector3(-0.10,0.30,0.151),Vector3(-0.075,0.27,0.179),Vector3(0,0.255,0.188),Vector3(0.075,0.27,0.179),Vector3(0.10,0.30,0.151)], 0.012, gold_light)
	# Thick hood roll and split opening: the neckline has genuine back depth.
	_oval(spine, Vector3(0,0.30,-0.095), Vector3(0.265,0.19,0.14), blue_dark)
	_tube(spine, [Vector3(-0.23,0.25,0.04),Vector3(-0.17,0.36,0.07),Vector3(-0.105,0.37,0.055)], 0.043, blue_light, 0.75)
	_tube(spine, [Vector3(0.23,0.25,0.04),Vector3(0.17,0.36,0.07),Vector3(0.105,0.37,0.055)], 0.043, blue_light, 0.75)
	_oval(neck, Vector3(0,0.025,0.01), Vector3(0.09,0.13,0.085), _mat("skin", "e9aa73"))
	for side in [-1.0, 1.0]:
		var edge: Array = [Vector3(side*0.115,-0.26,0.177),Vector3(side*0.14,-0.08,0.197),Vector3(side*0.155,0.12,0.179),Vector3(side*0.105,0.29,0.153)]
		_tube(coat, edge, 0.011, blue_dark)
		_tube(coat, edge.map(func(p): return p + Vector3(side*0.012,0,0.008)), 0.004, zip)
		for tooth in range(14):
			var y: float = -0.23 + float(tooth) * 0.031
			_oval(coat, Vector3(side*(0.125 + (y+0.23)*0.045),y,0.20), Vector3(0.006,0.006,0.004), zip)
		_tube(spine, [Vector3(side*0.145,0.29,0.175),Vector3(side*0.155,0.17,0.221),Vector3(side*0.145,0.045,0.229)], 0.009, cord)
		_oval(spine, Vector3(side*0.145,0.035,0.229), Vector3(0.011,0.024,0.011), zip)
		_tube(coat, [Vector3(side*0.205,-0.10,0.163),Vector3(side*0.235,-0.145,0.153),Vector3(side*0.19,-0.225,0.166)], 0.008, blue_dark)
		_tube(coat, [Vector3(side*0.211,-0.105,0.172),Vector3(side*0.238,-0.145,0.160),Vector3(side*0.195,-0.22,0.172)], 0.003, seam)
		# Small curved pigment folds across the jacket hips and golden tee.
		_tube(coat, [Vector3(side*0.17,-0.18,0.182),Vector3(side*0.21,-0.19,0.17),Vector3(side*0.25,-0.18,0.13)], 0.004, blue_light)
	_loft(coat, [Vector4(-0.29,0.24,0.16,0),Vector4(-0.275,0.26,0.167,0),Vector4(-0.24,0.26,0.168,0)], blue_dark)
	for n in range(11):
		var angle: float = PI * 0.16 + float(n) * PI * 0.068
		_tube(coat, [Vector3(cos(angle)*0.26,-0.28,sin(angle)*0.17),Vector3(cos(angle)*0.26,-0.245,sin(angle)*0.17)], 0.0025, blue_light)
	_tube(coat, [Vector3(-0.08,-0.15,0.21),Vector3(-0.015,-0.17,0.22),Vector3(0.085,-0.15,0.208)], 0.005, gold_light)

func _front_panel(parent: Node3D, rows: Array, material: Material) -> void:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	for row in rows:
		for n in range(9):
			var x: float = (float(n)/8.0*2.0-1.0)*row.y
			vertices.append(Vector3(x,row.x,row.z + (1.0-pow(x/maxf(row.y,0.001),2))*0.026))
			normals.append(Vector3(x/maxf(row.y,0.001)*0.43,0,1).normalized())
	for row in range(rows.size()-1):
		for n in range(8):
			var i: int=row*9+n
			indices.append_array(PackedInt32Array([i,i+9,i+1,i+1,i+9,i+10]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
	var geometry=ArrayMesh.new();geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_mesh(parent,geometry,material)

func _build_arm(spine: Node3D, side: String) -> void:
	var sign: float = -1.0 if side == "near" else 1.0
	var jacket = _mat("jacket", "2e4d6b")
	var blue_light = _mat("jacket_light", "52778d")
	var rib = _mat("jacket_dark", "1a3048")
	var skin = _mat("skin", "e9aa73")
	var shoulder = _joint("shoulder_"+side, spine, Vector3(sign*0.275,0.20,0))
	shoulder.rotation.z=sign*0.095
	_oval(shoulder,Vector3.ZERO,Vector3(0.102,0.105,0.10),jacket)
	_loft(shoulder,[Vector4(-0.30,0.087,0.09,0.01),Vector4(-0.23,0.105,0.105,0),Vector4(-0.10,0.115,0.115,0),Vector4(0.01,0.092,0.09,0)],jacket,20)
	var elbow = _joint("elbow_"+side, shoulder, Vector3(0,-0.285,0.015))
	elbow.rotation.x=-0.23
	_oval(elbow,Vector3.ZERO,Vector3(0.09,0.09,0.094),jacket)
	_loft(elbow,[Vector4(-0.285,0.072,0.075,0),Vector4(-0.245,0.092,0.095,0),Vector4(-0.12,0.09,0.095,0.015),Vector4(0.02,0.09,0.092,0)],jacket,20)
	for n in range(3):
		var y: float=-0.12-float(n)*0.045
		_tube(elbow,[Vector3(-0.07,y,0.05),Vector3(0,y-0.013,0.099),Vector3(0.07,y+0.004,0.045)],0.004,blue_light)
	_loft(elbow,[Vector4(-0.29,0.074,0.076,0),Vector4(-0.275,0.08,0.08,0),Vector4(-0.245,0.083,0.084,0)],rib,20)
	var wrist=_joint("wrist_"+side,elbow,Vector3(0,-0.28,0))
	wrist.scale=Vector3(1.08,1.08,1.04)
	_loft(wrist,[Vector4(-0.15,0.04,0.035,0.01),Vector4(-0.10,0.068,0.046,0.01),Vector4(-0.025,0.069,0.042,0),Vector4(0.025,0.046,0.038,0)],skin,20)
	# Soft palm with separate rounded fingers; the index stays readable when pointing.
	var digits=[]
	for finger in range(4):
		var x: float=(float(finger)-1.5)*.029
		var digit=_joint("finger_"+side+str(finger),wrist,Vector3(x,-.105,.012))
		var length_value: float=[.085,.095,.087,.066][finger]
		_oval(digit,Vector3(0,-length_value*.36,.009),Vector3(.020,length_value*.61,.025),skin)
		digits.append(digit)
	var thumb=_joint("thumb_"+side,wrist,Vector3(-sign*.065,-.055,.015))
	_oval(thumb,Vector3(-sign*.012,-.020,.021),Vector3(.032,.047,.030),skin)
	thumb.rotation.z=sign*.45
	hands[side]={"digits":digits,"thumb":thumb}

func _build_leg(hips: Node3D, side: String) -> void:
	var sign: float=-1.0 if side=="near" else 1.0
	var denim=_mat("denim","3c5a70")
	var denim_light=_mat("denim_light","57768a")
	var denim_dark=_mat("denim_dark","293e52")
	var thigh=_joint("thigh_"+side,hips,Vector3(sign*0.14,-0.015,0))
	thigh.rotation.z=-sign*.045
	_oval(thigh,Vector3.ZERO,Vector3(0.122,0.10,0.126),denim)
	var thigh_shape=Node3D.new();thigh.add_child(thigh_shape);thigh_shape.scale.y=0.34/0.405
	_loft(thigh_shape,[Vector4(-0.415,0.092,0.095,0),Vector4(-0.32,0.105,0.11,0),Vector4(-0.14,0.12,0.125,0),Vector4(0.03,0.125,0.13,0)],denim,24)
	_tube(thigh_shape,[Vector3(sign*0.11,-0.05,0.065),Vector3(sign*0.11,-0.21,0.065),Vector3(sign*0.086,-0.40,0.047)],0.0035,denim_light)
	var knee=_joint("knee_"+side,thigh,Vector3(0,-0.34,0))
	# Rounded cloth overlaps the open loft ends throughout a deep knee bend.
	_oval(knee,Vector3.ZERO,Vector3(0.096,0.10,0.102),denim)
	var knee_shape=Node3D.new();knee.add_child(knee_shape);knee_shape.scale.y=0.34/0.405
	_loft(knee_shape,[Vector4(-0.40,0.081,0.08,0),Vector4(-0.34,0.084,0.082,0.01),Vector4(-0.20,0.09,0.089,0.005),Vector4(-0.03,0.095,0.101,0),Vector4(0.025,0.094,0.10,0)],denim,24)
	for n in range(3):
		var y: float=-0.065-float(n)*0.055
		_tube(knee_shape,[Vector3(-0.076,y,0.05),Vector3(-0.02,y-0.012,0.098),Vector3(0.064,y+0.006,0.067)],0.0035,denim_light)
	_loft(knee_shape,[Vector4(-0.405,0.085,0.085,0),Vector4(-0.37,0.095,0.088,0),Vector4(-0.35,0.092,0.085,0)],denim_light,24)
	_tube(knee_shape,[Vector3(-0.082,-0.37,0.018),Vector3(0,-0.38,0.092),Vector3(0.08,-0.37,0.02)],0.0035,denim_dark)
	var ankle=_joint("ankle_"+side,knee,Vector3(0,-0.34,0))
	ankle.rotation.y=sign*.18
	_joint("toe_"+side,ankle,Vector3(0,-0.18,0.24))
	_build_shoe(ankle,sign)

func _build_shoe(ankle: Node3D, side: float) -> void:
	var sole=_mat("sole","e1d4b5")
	var toe=_mat("toe","f0dfbc")
	var canvas=_mat("shoe","263e54")
	var stitching=_mat("stitching","af9e80")
	_shoe_surface(ankle,[Vector4(-0.14,0.045,0.023,-0.17),Vector4(-0.12,0.115,0.029,-0.17),Vector4(0.02,0.135,0.029,-0.17),Vector4(0.20,0.145,0.029,-0.17),Vector4(0.32,0.105,0.026,-0.17),Vector4(0.35,0.02,0.015,-0.17)],sole)
	_shoe_surface(ankle,[Vector4(-0.13,0.03,0.04,-0.09),Vector4(-0.10,0.11,0.10,-0.09),Vector4(0.02,0.12,0.105,-0.09),Vector4(0.17,0.13,0.078,-0.10),Vector4(0.28,0.105,0.055,-0.11),Vector4(0.33,0.02,0.02,-0.11)],canvas)
	_shoe_surface(ankle,[Vector4(0.15,0.12,0.055,-0.11),Vector4(0.23,0.13,0.055,-0.11),Vector4(0.31,0.095,0.045,-0.12),Vector4(0.34,0.025,0.015,-0.13)],toe)
	_oval(ankle,Vector3(0,-0.005,0.025),Vector3(0.065,0.022,0.13),canvas)
	for n in range(4):
		var z: float=-0.025+float(n)*0.043
		var y: float=0.015-float(n)*0.009
		_tube(ankle,[Vector3(-0.07,y-0.012,z-0.012),Vector3(0,y+0.012,z+0.005),Vector3(0.07,y-0.012,z+0.012)],0.006,sole)
		for x in [-0.074,0.074]:
			_oval(ankle,Vector3(x,y-0.01,z),Vector3(0.009,0.006,0.009),stitching)
	_tube(ankle,[Vector3(-0.13,-0.145,-0.04),Vector3(-0.14,-0.145,0.14),Vector3(-0.09,-0.145,0.30),Vector3(0.09,-0.145,0.30),Vector3(0.14,-0.145,0.14),Vector3(0.13,-0.145,-0.04)],0.004,stitching)
	# A little stitched ivory lightning mark, built onto the sneaker's outer side.
	_tube(ankle,[Vector3(side*0.124,-0.055,0.04),Vector3(side*0.132,-0.075,0.08),Vector3(side*0.132,-0.068,0.12),Vector3(side*0.13,-0.10,0.105)],0.0055,toe)

func _shoe_surface(parent: Node3D, rings: Array, material: Material) -> void:
	# Rotate a smooth loft so its length runs heel-to-toe along +Z.
	var adjusted: Array=[]
	for ring in rings:
		adjusted.append(Vector4(ring.x,ring.y,ring.z,-ring.w))
	var geometry=_loft(parent,adjusted,material,24)
	geometry.rotation.x=PI*0.5

func _build_head(head: Node3D, crown: Node3D) -> void:
	var skin=_mat("skin","e9aa73")
	var skin_light=_mat("skin_light","f0b67e")
	var ear_inner=_mat("ear_inner","c78c65")
	var face_mesh=_loft(head,[Vector4(-0.29,0.075,0.10,0.015),Vector4(-0.25,0.175,0.18,0.01),Vector4(-0.16,0.295,0.225,0),Vector4(-0.03,0.335,0.258,-0.01),Vector4(0.12,0.345,0.27,-0.018),Vector4(0.25,0.30,0.24,-0.02),Vector4(0.32,0.16,0.15,-0.02),Vector4(0.34,0.01,0.01,-0.02)],skin,36)
	_paint_cheeks(face_mesh)
	for side in [-1.0,1.0]:
		var ear=_oval(head,Vector3(side*0.332,-0.025,-0.008),Vector3(0.085,0.115,0.065),skin)
		ear.rotation.z=side*-0.12
		_oval(head,Vector3(side*0.365,-0.025,0.041),Vector3(0.042,0.071,0.018),ear_inner)
		_oval(head,Vector3(side*0.36,-0.045,0.052),Vector3(0.023,0.032,0.018),skin_light)
	_oval(head,Vector3(0,-0.07,0.263),Vector3(0.040,0.037,0.018),skin_light)

	_build_eyes(head)
	var mouth=Node3D.new();mouth.name="mouth";mouth.position=Vector3(0,-0.16,0.235);head.add_child(mouth);face.mouth=mouth;joints.mouth=mouth
	var closed=Node3D.new();mouth.add_child(closed);face.closed=closed
	var smile_points: Array=[]
	for n in range(13):
		var t: float=float(n)/12.0*2.0-1.0
		smile_points.append(Vector3(t*0.125,-0.030*(1.0-t*t)+t*.006,0.016*(1.0-t*t)))
	_tube(closed,smile_points,0.0065,_mat("mouth_line","8d573e"))
	_tube(closed,[Vector3(-0.05,-0.041,0.01),Vector3(0,-0.046,0.019),Vector3(0.05,-0.04,0.01)],0.004,_mat("lip","d9906a"))
	var open=Node3D.new();open.name="mouth_open";open.position=Vector3(0,-0.016,0.015);mouth.add_child(open);face.mouth_open=open
	Paint.grin(open,Vector3.ZERO,.105,.075,_mat("mouth_inside","6f3a2d"))
	_oval(open,Vector3(0,-.047,.009),Vector3(.047,.016,.003),_mat("tongue","ce8b76"))
	var tooth=Paint.grin(open,Vector3(0,.003,.010),.091,.022,_mat("teeth","fff0d4"))
	face.teeth=tooth
	var surprised=Node3D.new();mouth.add_child(surprised);face.surprised=surprised
	_oval(surprised,Vector3(0,-.022,.020),Vector3(.037,.050,.004),_mat("mouth_inside","6f3a2d"))
	for side in ["near","far"]:
		var sign_value: float=-1 if side=="near" else 1
		var cheek=_joint("cheek_"+side,head,Vector3(sign_value*.205,-.125,.167))
		# The original painted blush stays on the skin; retain the expression pivot.
	for paint in ["mouth_line","mouth_inside","tongue","teeth"]:
		_materials[paint].shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_build_hair(crown)

func _build_eyes(head: Node3D) -> void:
	# Shallow ink and cream shapes read as an illustration wrapped onto the head.
	var white=_mat("eye_white","fff3dc")
	var iris=_mat("iris","79513c")
	var ink=_mat("pupil","34291f")
	var glint=_mat("glint","fff8e7")
	var brow_mat=_mat("brow","543725")
	for paint in [white,iris,ink,glint,brow_mat]:
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in ["near","far"]:
		var sign: float=-1.0 if side=="near" else 1.0
		var eye=Node3D.new();eye.name="eye_"+side;eye.position=Vector3(sign*0.14,0.014,0.234);head.add_child(eye);face["eye_"+side]=eye;joints["eye_"+side]=eye
		eye.rotation.y=sign*0.28
		eye.scale.x=.90
		_eye_rest[side]=eye.transform
		Paint.almond(eye,Vector3.ZERO,Vector2(.091,.096),brow_mat)
		Paint.almond(eye,Vector3(0,-.003,.006),Vector2(.082,.084),white)
		var pupil=Node3D.new();pupil.name="pupil_"+side;pupil.position=Vector3(0,0,0.018);eye.add_child(pupil);face["pupil_"+side]=pupil;joints["pupil_"+side]=pupil
		_oval(pupil,Vector3.ZERO,Vector3(0.053,0.063,0.004),iris)
		_oval(pupil,Vector3(0,0.002,0.004),Vector3(0.031,0.047,0.003),ink)
		_oval(pupil,Vector3(-0.016,0.027,0.008),Vector3(0.012,0.014,0.002),glint)
		var eyebrow=Node3D.new();eyebrow.name="brow_"+side;eyebrow.position=Vector3(sign*0.145,0.151,0.239);head.add_child(eyebrow);face["brow_"+side]=eyebrow;joints["brow_"+side]=eyebrow;_brow_rest[side]=eyebrow.position
		_tube(eyebrow,[Vector3(-0.074,0,0),Vector3(-0.03,0.017,0.008),Vector3(0.028,0.018,0.008),Vector3(0.070,0.004,0)],0.011,brow_mat,0.55)

func _build_hair(crown: Node3D) -> void:
	var dark=_mat("hair_dark","372317")
	var chestnut=_mat("hair","54331c")
	var warm=_mat("hair_warm","68432c")
	var light=_mat("hair_light","785137")
	_oval(crown,Vector3(0,.01,-.055),Vector3(.344,.140,.270),dark)
	# Long swept masses cross the crown; small contours follow the same flow.
	for n in range(7):
		var x: float=-.28+n*.083
		var y: float=.025+sin(float(n)/6.0*PI)*.055
		_lock(crown,Vector3(x-.035,y,-.19),Vector3(x-.16,y+.23,.005),Vector3(x+.11,y-.10,.24),.075,[chestnut,warm,chestnut,dark][n%4])
	for n in range(4):
		var x: float=-.29+n*.15
		_lock(crown,Vector3(x-.035,.07,.04),Vector3(x+.04,.15,.29),Vector3(x+.13,-.12+float(n%2)*.04,.24),.077,[chestnut,warm,chestnut,dark][n])
	for side in [-1.0,1.0]:
		_lock(crown,Vector3(side*.25,.025,-.13),Vector3(side*.365,-.02,.01),Vector3(side*.30,-.22,.055),.052,dark)
	# A loose forelock breaks the outline without covering the eyebrows.
	_lock(crown,Vector3(-.19,.07,-.04),Vector3(-.32,.27,.03),Vector3(-.36,.14,.10),.043,warm)
	for n in range(5):
		var x: float=-.22+n*.09
		_tube(crown,[Vector3(x,.117,-.10),Vector3(x-.018,.16,.01),Vector3(x+.05,.07,.16)],.0025,light,.4)

func _lock(parent: Node3D, start: Vector3, control: Vector3, tip: Vector3, width: float, material: Material) -> void:
	var vertices=PackedVector3Array();var normals=PackedVector3Array();var colours=PackedColorArray();var indices=PackedInt32Array()
	var rows: int=14;var around: int=16
	for row in range(rows+1):
		var t: float=float(row)/float(rows)
		var at: Vector3=(1.0-t)*(1.0-t)*start+2.0*(1.0-t)*t*control+t*t*tip
		var tangent: Vector3=(2.0*(1.0-t)*(control-start)+2.0*t*(tip-control)).normalized()
		var across: Vector3=tangent.cross(Vector3.FORWARD).normalized()
		if across.length_squared()<0.1:across=Vector3.RIGHT
		var normal: Vector3=across.cross(tangent).normalized()
		var radius: float=width*(0.60+sin(t*PI)*0.45)*pow(1.0-t,0.48)+0.001
		for n in range(around+1):
			var angle: float=float(n)*TAU/float(around)
			var direction: Vector3=across*cos(angle)+normal*sin(angle)*0.62
			vertices.append(at+direction*radius)
			normals.append(direction.normalized())
			var pigment: float=0.94+sin(angle*3.0+float(row)*0.55)*0.055
			colours.append(Color(pigment,pigment,pigment,1))
	for row in range(rows):
		for n in range(around):
			var i: int=row*(around+1)+n
			indices.append_array(PackedInt32Array([i,i+1,i+around+1,i+1,i+around+2,i+around+1]))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colours;arrays[Mesh.ARRAY_INDEX]=indices
	var geometry=ArrayMesh.new();geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_mesh(parent,geometry,material)

func set_expression(blink: float, gaze: Vector2, mouth_open: float, smile: float, brow: float) -> void:
	if not _built or face.is_empty():return
	var delighted: bool=emotion in ["delight","celebrate","cheer","laugh"]
	var curious: bool=emotion in ["hint","curious","spot","point","thinking"]
	var surprise: bool=emotion=="surprise"
	var unsure: bool=emotion=="uncertain"
	var focused: bool=emotion in ["concentrate","notebook"]
	var eye_height: float=.64 if delighted else 1.10 if surprise else .78 if focused else .85
	for side in ["near","far"]:
		var near_side: bool=side=="near"
		var eye: Node3D=face["eye_"+side]
		eye.scale.y=maxf(.04,(1-clampf(blink,0,1))*eye_height)
		face["pupil_"+side].position=Vector3(clampf(gaze.x,-1,1)*.010,clampf(gaze.y,-1,1)*.010,.018)
		var eyebrow: Node3D=face["brow_"+side]
		var lift: float=.048 if surprise else .020 if delighted else (.038 if near_side else -.004) if curious else .017 if unsure else -.010 if focused else .004
		eyebrow.position=_brow_rest[side]+Vector3(0,lift,0)
		eyebrow.rotation.z=(.22 if near_side else -.10) if curious else (-.16 if near_side else .16) if unsure else (.13 if near_side else -.13) if delighted else (-.10 if near_side else .10) if focused else 0.0
		joints["cheek_"+side].position.y=-.125+(.018 if delighted else .004)
	face.mouth.scale=Vector3(.95+smile*.22,1.0+smile*.12,1)
	face.mouth.rotation.z=-.085 if curious else .035 if unsure else 0.0
	face.surprised.visible=surprise
	face.mouth_open.visible=not surprise and mouth_open>.035
	face.closed.visible=not surprise and not face.mouth_open.visible
	face.teeth.visible=delighted or emotion in ["present","wave"]
	face.mouth_open.scale.y=maxf(.05,mouth_open*1.5)
	for hand in hands.values():
		for i in range(4):hand.digits[i].rotation.x=.65 if curious and i>0 else .20 if emotion=="notebook" else -.10 if delighted or emotion=="wave" else .10

func _paint_cheeks(part: MeshInstance3D) -> void:
	# Pigment follows the curved skin itself, instead of floating blush geometry.
	var arrays: Array=part.mesh.surface_get_arrays(0)
	var colours: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for n in range(vertices.size()):
		var point: Vector3=vertices[n]
		var tint: float=exp(-pow((absf(point.x)-0.19)/0.075,2)-pow((point.y+0.11)/0.075,2))*clampf(point.z/0.18,0,1)
		colours[n]*=Color(1.0,1.0-tint*0.065,1.0-tint*0.045,1)
	arrays[Mesh.ARRAY_COLOR]=colours
	var geometry=ArrayMesh.new();geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	part.mesh=geometry

func _build_notebook() -> void:
	var book=Node3D.new()
	book.name="MarkNotebook"
	book.position=Vector3(0,-0.075,0.075)
	book.rotation=Vector3(-0.20,0.05,-0.10)
	joints.wrist_near.add_child(book)
	props.notebook=book
	var pages=BoxMesh.new();pages.size=Vector3(0.23,0.31,0.028)
	_mesh(book,pages,_mat("paper","e8d9b5"))
	var cover=BoxMesh.new();cover.size=Vector3(0.255,0.335,0.009)
	for z in [-0.020,0.020]:
		_mesh(book,cover,_mat("book_cover","396259"),Vector3(0,0,z))
	var spine=BoxMesh.new();spine.size=Vector3(0.018,0.335,0.047)
	_mesh(book,spine,_mat("book_spine","b38e47"),Vector3(-0.128,0,0))
	for y in [-0.10,0.08]:
		_tube(book,[Vector3(-0.14,y,0.026),Vector3(-0.11,y,0.030)],0.006,_mat("book_rings","d5bb76",0.55))
	_tube(book,[Vector3(-0.012,-0.08,0.028),Vector3(0,0.075,0.028)],0.003,_mat("book_leaf","d7bc78"))
	for side in [-1.0,1.0]:
		_oval(book,Vector3(side*0.023,0.005+side*0.025,0.030),Vector3(0.026,0.012,0.003),_mat("book_leaf","d7bc78"))
	book.hide()

func set_pose_state(state: String) -> void:
	if props.has("notebook"):
		props.notebook.visible=state in ["notebook","present"]

func _batch_static(parent: Node3D) -> void:
	for child in parent.get_children():
		if child is Node3D and not child is MeshInstance3D:
			_batch_static(child)
	var groups: Dictionary={}
	for child in parent.get_children():
		if child is MeshInstance3D and child.mesh!=null:
			var material: Material=child.material_override
			var key: int=material.get_instance_id() if material!=null else 0
			if not groups.has(key):groups[key]=[]
			groups[key].append(child)
	for group in groups.values():
		if group.size()<2:continue
		var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in group:
			# PrimitiveMesh has no COLOR stream. SurfaceTool append_from otherwise
			# fills it with black when joining an already-coloured custom surface.
			var source: Mesh=part.mesh
			var arrays: Array=source.surface_get_arrays(0)
			if arrays[Mesh.ARRAY_COLOR]==null or arrays[Mesh.ARRAY_COLOR].is_empty():
				var colours=PackedColorArray();colours.resize(arrays[Mesh.ARRAY_VERTEX].size());colours.fill(Color.WHITE)
				arrays[Mesh.ARRAY_COLOR]=colours
				var coloured=ArrayMesh.new();coloured.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				source=coloured
			surface.append_from(source,0,part.transform)
		var geometry=surface.commit()
		var combined=_mesh(parent,geometry,group[0].material_override)
		combined.name="SculptedBatch"
		for part in group:
			parent.remove_child(part)
			part.free()

func set_emotion(state: String) -> void:
	emotion=state
