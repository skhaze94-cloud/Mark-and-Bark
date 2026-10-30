extends Node3D
## Joint-mounted sculptural details. Updated only by the character presenter.
var tails=[]
var tail_chains=[]
var tail_velocity=0.0
var tail_bend=0.0
var skin_rig: Skeleton3D
var leaves=[]
var clock=0.0
var role="mark"
var materials={}
var pieces=[]
var motes=[]
var flourish_age=2.0
var was_cheering=false
var settle=0.0
var emotion="idle"
var previous_emotion="idle"

func mat(id,colour,metal=0.0):
 if materials.has(id):return materials[id]
 var m=StandardMaterial3D.new();m.albedo_color=Color(colour);m.roughness=1.0;m.metallic=metal*.15;m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
 if metal>0:m.roughness=.9
 materials[id]=m;return m

func oval(parent,at,radius,material):
 var mesh=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=12;mesh.rings=7
 var part=MeshInstance3D.new();part.mesh=mesh;part.material_override=material;part.position=at;part.scale=radius;parent.add_child(part);pieces.append(part);return part

func rod(parent,a,b,r,material):
 var mesh=CylinderMesh.new();mesh.top_radius=r;mesh.bottom_radius=r;mesh.height=a.distance_to(b);mesh.radial_segments=8
 var part=MeshInstance3D.new();part.mesh=mesh;part.material_override=material;part.position=(a+b)*.5;part.quaternion=Quaternion(Vector3.UP,(b-a).normalized());parent.add_child(part);pieces.append(part);return part

func ring(parent,at,r,thickness,material):
 var mesh=TorusMesh.new();mesh.inner_radius=r-thickness;mesh.outer_radius=r+thickness;mesh.rings=20;mesh.ring_segments=8
 var part=MeshInstance3D.new();part.mesh=mesh;part.material_override=material;part.position=at;part.rotation.x=PI/2;parent.add_child(part);pieces.append(part);return part

func pivot(parent,at):
 var p=Node3D.new();p.position=at;parent.add_child(p);return p

func leaf(parent,at,angle,length_value,width,material):
 var p=pivot(parent,at);p.rotation=angle
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var a=Vector3(0,0,0);var b=Vector3(-width,length_value*.48,.025);var c=Vector3(0,length_value*.52,.07);var d=Vector3(width,length_value*.48,.025);var e=Vector3(0,length_value,0)
 for v in [a,c,b,b,c,e,e,c,d,d,c,a]:st.add_vertex(v)
 st.generate_normals();var m=MeshInstance3D.new();m.mesh=st.commit();m.material_override=material;p.add_child(m);pieces.append(m)
 rod(p,a+Vector3(0,0,.006),c+Vector3(0,0,.006),.004,mat("vein","cfcd7a"))
 rod(p,c+Vector3(0,0,.006),e,.003,mat("vein","cfcd7a"));return p

func build(model,kind):
 role=kind
 skin_rig=model.soft_skin
 if role=="mark":mark_details(model)
 else:bark_details(model)
 batch(model)
 build_flourish()

func mark_details(model):
 var face_head=model.joints.head;var spine=model.joints.spine
 mat("scarf","bd5345").cull_mode=BaseMaterial3D.CULL_DISABLED
 var brass=mat("brass","dbb96e",.65);var leather=mat("leather","9c563b");var stitch=mat("stitch","f0d39a")
 for side in [-1,1]:
  for i in range(3):oval(face_head,Vector3(side*(.18+i*.027),-.105+(i%2)*.022,.221-i*.009),Vector3(.007,.008,.004),mat("freckles","ad704e"))
 # A soft red neckerchief creates a clear colour accent at gameplay size.
 oval(spine,Vector3(0,.355,.035),Vector3(.17,.075,.115),mat("scarf","bd5345"))
 oval(spine,Vector3(.13,.315,.16),Vector3(.065,.062,.05),mat("scarflight","ea8260"))
 for i in range(2):
  var p=pivot(spine,Vector3(.13+i*.035,.31,.12));p.rotation.z=-.55-i*.2
  var mid=pivot(p,Vector3(0,-(.34-i*.07)*.5,0))
  skin_rig.ribbon("PaintedScarf"+str(i),[p,mid],.34-i*.07,.065,mat("scarf","bd5345"))
  tails.append(p);tail_chains.append(mid)
 # Cross-body leather strap and rounded, gusseted notebook satchel.
 rod(spine,Vector3(-.23,.26,.16),Vector3(.23,-.23,.19),.026,leather)
 var bag=pivot(spine,Vector3(.27,-.19,-.035))
 oval(bag,Vector3.ZERO,Vector3(.15,.20,.115),leather)
 oval(bag,Vector3(0,.065,.088),Vector3(.158,.11,.043),mat("flap","be7950"))
 ring(bag,Vector3(0,.015,.135),.024,.007,brass)
 for i in range(7):oval(bag,Vector3(-.11+i*.036,.09,.127),Vector3(.007,.003,.003),stitch)
 # Goggles are clipped to the satchel, leaving the expressive hairline clear.
 var head=pivot(bag,Vector3(0,-.06,.10));head.scale=Vector3.ONE*.43
 rod(head,Vector3(-.31,.235,.08),Vector3(-.24,.235,.245),.028,leather)
 rod(head,Vector3(.31,.235,.08),Vector3(.24,.235,.245),.028,leather)
 for x in [-.135,.135]:
  oval(head,Vector3(x,.235,.245),Vector3(.105,.082,.028),leather)
  ring(head,Vector3(x,.235,.27),.075,.012,brass)
  oval(head,Vector3(x,.235,.277),Vector3(.062,.062,.012),mat("glass","3f9eaa",.25))
  oval(head,Vector3(x-.021,.26,.291),Vector3(.018,.008,.004),stitch)
 rod(head,Vector3(-.05,.235,.278),Vector3(.05,.235,.278),.014,brass)
 # A small enamel star pin, visible on the opposite lapel.
 var pin=pivot(spine,Vector3(-.225,.15,.175))
 oval(pin,Vector3.ZERO,Vector3(.049,.049,.012),brass)
 oval(pin,Vector3(0,0,.011),Vector3(.034,.034,.009),mat("pin","4b9d90"))
 for i in range(4):
  var angle=i*PI/2
  rod(pin,Vector3.ZERO+Vector3(0,0,.024),Vector3(cos(angle)*.023,sin(angle)*.023,.024),.004,stitch)

func bark_details(model):
 var crown=model.joints.crown;var spine=model.joints.spine
 var green=mat("emerald","49825b");green.cull_mode=BaseMaterial3D.CULL_DISABLED
 var lime=mat("lime","a6b85f");lime.cull_mode=BaseMaterial3D.CULL_DISABLED
 var copper=mat("copper","d3924d");copper.cull_mode=BaseMaterial3D.CULL_DISABLED
 for i in range(4):
  var a=i*2.39996
  var p=leaf(crown,Vector3((-1 if i%2==0 else 1)*.29,-.06+(i/2)*.07,sin(a)*.13),Vector3(.20,a*.1,(1 if i%2==0 else -1)*1.1),.19+(i%3)*.025,.070,[green,lime,copper][i%3])
  leaves.append({"node":p,"rest":p.rotation,"phase":float(i)})
 # Moss pads follow the woody shoulder contours, away from the facial panel.
 for side in [-1,1]:
  for i in range(3):oval(spine,Vector3(side*(.25+i*.013),.35-i*.052,-.09),Vector3(.065,.047,.065),green if i%2 else lime)
 # Two little shelf mushrooms have ivory stalks, curved caps and raised spots.
 for i in range(2):
  var p=pivot(spine,Vector3(-.30-i*.07,.36-i*.08,.025))
  rod(p,Vector3.ZERO,Vector3(-.025,.11,0),.017,mat("stem","ead8af"))
  oval(p,Vector3(-.025,.11,0),Vector3(.082,.045,.065),mat("cap","c9664b"))
  for n in range(3):oval(p,Vector3(-.06+n*.035,.143,.012),Vector3(.009,.004,.009),mat("stem","ead8af"))
 # A tiny acorn on a cord gives the tree a personal keepsake.
 var cord=mat("cord","755139")
 rod(spine,Vector3(-.19,.39,.25),Vector3(0,.03,.29),.009,cord)
 rod(spine,Vector3(.19,.39,.25),Vector3(0,.03,.29),.009,cord)
 oval(spine,Vector3(0,-.015,.31),Vector3(.055,.073,.043),mat("acorn","dfb466"))
 oval(spine,Vector3(0,.033,.31),Vector3(.064,.028,.049),mat("acorncap","795335"))
 rod(spine,Vector3(0,.05,.31),Vector3(.014,.08,.31),.01,cord)
 # A small living blossom behind the crown, with individually cupped petals.
 var flower=pivot(crown,Vector3(.22,.20,-.04))
 for i in range(5):
  var a=i*TAU/5
  oval(flower,Vector3(cos(a)*.046,sin(a)*.046,0),Vector3(.036,.036,.013),mat("petal","f1d6a4"))
 oval(flower,Vector3(0,0,.017),Vector3(.025,.025,.015),mat("pollen","d79d3e"))

func advance(delta,motion,still,reduced):
 if emotion!=previous_emotion:
  if previous_emotion=="laugh":settle=.8
  previous_emotion=emotion
 if reduced:
  for mote in motes:mote.hide()
 if still:return
 if reduced:
  flourish_age=2.0
  for mote in motes:mote.hide()
 else:
  settle=maxf(0,settle-delta*3.0)
  clock+=delta
  flourish_age+=delta
  for i in range(motes.size()):
   var mote=motes[i]
   mote.visible=flourish_age<1.2
   if mote.visible:
    var t=flourish_age
    var side=-1.0 if i%2==0 else 1.0
    mote.position=Vector3(side*(.30+t*.22)+sin(t*4+i)*.06,1.65+t*.5-t*t*.6+i*.055,.16)
    mote.rotation=Vector3(t*2+i,t+i,t*3+i)
    mote.scale=Vector3.ONE*(1.0-t/1.2)
 var speed=clampf(absf(motion.x)/260.0,0,1)
 # Damped follow-through responds to acceleration and landing, and rests calmly.
 var dt=clampf(delta,0,.05)
 var target=-speed*.65-settle*.22
 if reduced:
  tail_bend=0;tail_velocity=0
 else:
  tail_velocity+=(target-tail_bend)*65*dt
  tail_velocity*=exp(-12*dt)
  tail_bend=clampf(tail_bend+tail_velocity*dt,-1.0,.30)
 for i in range(tails.size()):
  tails[i].rotation.x=0 if reduced else tail_bend*.55
  tails[i].rotation.z=-.55-i*.2
  tail_chains[i].rotation.x=0 if reduced else tail_bend*(1.0+i*.15)
 if not tails.is_empty():skin_rig.sync()
 for item in leaves:
  var lift=.10 if emotion in ["curious","thinking","spot"] else 0.0
  item.node.rotation=item.rest if reduced else item.rest+Vector3(lift+sin(clock*2.7+item.phase)*(.015+speed*.06+settle*.07),0,cos(clock*3.1+item.phase)*(.015+settle*.03))

func batch(model):
 var boundaries=model.joints.values()+tails
 for item in leaves:boundaries.append(item.node)
 var groups={}
 for part in pieces:
  var anchor=part.get_parent()
  while anchor!=model and not anchor in boundaries:anchor=anchor.get_parent()
  var key=str(anchor.get_instance_id())+":"+str(part.material_override.get_instance_id())
  if not groups.has(key):groups[key]={"anchor":anchor,"parts":[]}
  groups[key].parts.append(part)
 for group in groups.values():
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for part in group.parts:st.append_from(part.mesh,0,group.anchor.global_transform.affine_inverse()*part.global_transform)
  var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=group.parts[0].material_override;group.anchor.add_child(mesh)
  for part in group.parts:part.get_parent().remove_child(part);part.free()
 pieces.clear()

func build_flourish():
 # Six reusable paper flecks; no frame-by-frame allocation or particle system.
 for i in range(6):
  var mote=leaf(self,Vector3.ZERO,Vector3.ZERO,.07,.022,mat("fleck","e9bf69" if role=="mark" else "e9bdab"))
  mote.hide();motes.append(mote)
 pieces.clear()

func celebrate():
 if flourish_age>=1.2:flourish_age=0.0

func land(strength):
 settle=clampf(strength,0,1)
