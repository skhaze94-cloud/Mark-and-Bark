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
