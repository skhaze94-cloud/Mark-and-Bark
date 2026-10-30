extends RefCounted
## Smooth, shallow ink shapes; no per-frame geometry allocation.
static func almond(parent: Node3D, at: Vector3, radius: Vector2, material: Material) -> MeshInstance3D:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rows=32
 for i in range(rows):
  var x0=-1.0+2.0*i/rows;var x1=-1.0+2.0*(i+1)/rows
  var a=sqrt(maxf(0,1-x0*x0));var b=sqrt(maxf(0,1-x1*x1))
  var p=[Vector3(x0*radius.x,a*radius.y*.83,.002*a),Vector3(x0*radius.x,-a*radius.y,.002*a),Vector3(x1*radius.x,b*radius.y*.83,.002*b),Vector3(x1*radius.x,-b*radius.y,.002*b)]
  for n in [0,2,1,2,3,1]:
   st.set_normal(Vector3(0,0,1));st.add_vertex(p[n])
 var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=material;mesh.position=at;parent.add_child(mesh);return mesh

static func grin(parent: Node3D, at: Vector3, width: float, depth: float, material: Material) -> MeshInstance3D:
 # Raised corners and a bowed lower edge; shared by the mouth and tooth band.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(32):
  var corners=[]
  for x in [-1.0+2.0*i/32.0,-1.0+2.0*(i+1)/32.0]:
   var lift=.035*x*x
   corners.append(Vector3(x*width,lift,.006*(1-x*x)))
   corners.append(Vector3(x*width,lift-depth*(1-x*x),.006*(1-x*x)))
  for n in [0,2,1,2,3,1]:
   st.set_normal(Vector3(0,0,1));st.add_vertex(corners[n])
 var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=material;mesh.position=at;parent.add_child(mesh);return mesh
