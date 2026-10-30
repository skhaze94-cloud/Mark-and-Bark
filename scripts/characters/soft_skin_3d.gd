extends Skeleton3D
## GPU skinning driven by the existing visual pivots. No physics or input ownership.
## Bone hierarchy mirrors pivots so rotated nonuniform scales retain their form.
var model: Node3D
var sources: Array[Node3D] = []
var bone_ids: Dictionary = {}
var bindings = Skin.new()
var surfaces: Array[MeshInstance3D] = []

func configure(owner_model: Node3D) -> void:
	model = owner_model
	name = "SoftSkeleton"
	model.add_child(self)

func relative(node: Node3D) -> Transform3D:
	var result = node.transform
	var ancestor = node.get_parent()
	while ancestor != model:
		result = ancestor.transform * result
		ancestor = ancestor.get_parent()
	return result

func bone(node: Node3D) -> int:
	if bone_ids.has(node): return bone_ids[node]
	var parent_id = -1
	if node.get_parent() != model: parent_id = bone(node.get_parent())
	var id = get_bone_count()
	add_bone(str(node.name))
	var rest_pose = relative(node)
	set_bone_parent(id,parent_id)
	set_bone_rest(id, node.transform)
	set_bone_pose(id, node.transform)
	bindings.add_bind(id, rest_pose.affine_inverse())
	sources.append(node)
	bone_ids[node] = id
	return id

func sync() -> void:
	for i in range(sources.size()):
		set_bone_pose(i, sources[i].transform)

func ribbon(label: String, chain: Array, length_value: float, width: float, material: Material) -> void:
	var first = bone(chain[0]); var second = bone(chain[1])
	var pose = relative(chain[0])
	var vertices = PackedVector3Array(); var normals = PackedVector3Array()
	var bones = PackedInt32Array(); var weights = PackedFloat32Array()
	var indices = PackedInt32Array()
	for row in range(17):
		var t = float(row)/16
		var w = width*(.65+.35*sin(t*PI))*(1-.7*pow(t,6))
		for side in [-1.0,0.0,1.0]:
			vertices.append(pose*Vector3(side*w,-t*length_value,.012*sin(t*PI)+(1-absf(side))*.012))
			normals.append(pose.basis*Vector3.BACK)
			var blend = smoothstep(.25,.75,t)
			bones.append_array(PackedInt32Array([first,second,0,0]))
			weights.append_array(PackedFloat32Array([1-blend,blend,0,0]))
	for row in range(16):
		for side in range(2):
			var i = row*3+side
			indices.append_array(PackedInt32Array([i,i+1,i+3,i+1,i+4,i+3]))
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_BONES]=bones; arrays[Mesh.ARRAY_WEIGHTS]=weights; arrays[Mesh.ARRAY_INDEX]=indices
	surface(label,arrays,material)

func surface(label: String, arrays: Array, material: Material) -> MeshInstance3D:
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var part = MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	add_child(part)
	part.skeleton = part.get_path_to(self)
	part.skin = bindings
	# Conservative bounds include jumping, waves and root spread. No stale rest cull.
	part.custom_aabb = AABB(Vector3(-2,-1,-2), Vector3(4,5,4))
	surfaces.append(part)
	return part

## One indexed surface through a shoulder/elbow/wrist or thigh/knee/ankle chain.
## The last bone is a rigid attachment anchor; the tip remains on its parent.
func limb(label: String, chain: Array, radii: Array, material: Material, depth: float = 1.0, wood: bool = false) -> void:
	var ids: Array[int] = []
	var rests: Array[Transform3D] = []
	for joint in chain:
		ids.append(bone(joint)); rests.append(relative(joint))
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var bones = PackedInt32Array()
	var weights = PackedFloat32Array()
	var indices = PackedInt32Array()
	const ROWS = 32
	const SIDES = 24
	for row in range(ROWS+1):
		var t = float(row)/ROWS * 2.0
		var segment = mini(int(t),1)
		var fraction = t-segment
		var a = rests[segment].origin
		var b = rests[segment+1].origin
		var tangent = (b-a).normalized()
		var across = tangent.cross(Vector3.FORWARD).normalized()
		var other = tangent.cross(across).normalized()
		var center = a.lerp(b,fraction)
		var radius = lerpf(radii[segment],radii[segment+1],smoothstep(0,1,fraction))
		# Soft but narrow blend zone avoids rubber hose limbs and an elbow hinge.
		var blend = smoothstep(.68,1.32,t)
		for side in range(SIDES+1):
			var angle = float(side)/SIDES*TAU
			var normal = (across*cos(angle)+other*sin(angle)/depth).normalized()
			var variation = 1.0+.025*sin(angle*5+t*4) if wood else 1.0+.015*sin(t*PI*4)
			vertices.append(center+(across*cos(angle)+other*sin(angle)*depth)*radius*variation)
			normals.append(normal)
			var shade = .91+.08*sin(angle*5+t*2) if wood else .98+.02*sin(angle*3+t*5)
			colors.append(Color("b67d3d")*Color(shade,shade,shade,1) if wood else Color(shade,shade,shade,1))
			bones.append_array(PackedInt32Array([ids[0],ids[1],0,0]))
			weights.append_array(PackedFloat32Array([1-blend,blend,0,0]))
	for row in range(ROWS):
		for side in range(SIDES):
			var i = row*(SIDES+1)+side
			indices.append_array(PackedInt32Array([i,i+SIDES+1,i+1,i+1,i+SIDES+1,i+SIDES+2]))
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
	arrays[Mesh.ARRAY_BONES]=bones; arrays[Mesh.ARRAY_WEIGHTS]=weights
	surface(label,arrays,material)

## Skin existing trunk geometry and its painted grain consistently across the
## hips, spine and head. The face stays rigid on the head for readable expressions.
func trunk_part(part: MeshInstance3D) -> void:
	var arrays = part.mesh.surface_get_arrays(0)
	var transform_to_model = relative(part)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bones = PackedInt32Array()
	var weights = PackedFloat32Array()
	var hips = bone(model.joints.hips)
	var spine = bone(model.joints.spine)
	var head = bone(model.joints.head)
	var low = relative(model.joints.spine).origin.y
	var high = relative(model.joints.head).origin.y
	for i in range(vertices.size()):
		vertices[i] = transform_to_model*vertices[i]
		if not normals.is_empty(): normals[i]=(transform_to_model.basis.inverse().transposed()*normals[i]).normalized()
		var lower = smoothstep(low-.22,low+.06,vertices[i].y)
		var upper = smoothstep(high-.25,high+.04,vertices[i].y)
		bones.append_array(PackedInt32Array([hips,spine,head,0]))
		weights.append_array(PackedFloat32Array([1-lower,lower*(1-upper),lower*upper,0]))
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_BONES]=bones; arrays[Mesh.ARRAY_WEIGHTS]=weights
	surface("PaintedTrunk",arrays,part.material_override)
	part.get_parent().remove_child(part); part.free()
