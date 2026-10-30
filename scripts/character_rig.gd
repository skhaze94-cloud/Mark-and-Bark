extends Sprite2D
# Native Godot bones deform the original painted action sprites. Physics is separate.
const CANVAS=Vector2(512,640)
const ANCHOR=Vector2(256,612)
const COLS=18
const ROWS=24
const LINKS=[
 ["FootLock","","origin"],["Hip","","hips"],["Head","Hip","neck"],
 ["ShoulderNear","Hip","shoulder_near"],["ElbowNear","ShoulderNear","elbow_near"],["WristNear","ElbowNear","wrist_near"],
 ["ShoulderFar","Hip","shoulder_far"],["ElbowFar","ShoulderFar","elbow_far"],["WristFar","ElbowFar","wrist_far"],
 ["ThighNear","Hip","hips"],["KneeNear","ThighNear","knee_near"],["AnkleNear","KneeNear","ankle_near"],["ToeNear","AnkleNear","toe_near"],
 ["ThighFar","Hip","hips"],["KneeFar","ThighFar","knee_far"],["AnkleFar","KneeFar","ankle_far"],["ToeFar","AnkleFar","toe_far"],
 ["Crown","Head","crown"],["LeafNear","Head","leaf_near"],["LeafFar","Head","leaf_far"],["Coat","Hip","coat"],
 ["EyeNear","Head","eye_near"],["EyeFar","Head","eye_far"],["BrowNear","Head","brow_near"],["BrowFar","Head","brow_far"],["Mouth","Head","mouth"]]
static var profiles={}
static var skin_cache={}
var tuning: Resource
var skeleton: Skeleton2D
var mesh: Polygon2D
var overlay: Node2D
var bones={}
var rest_globals={}
var global_poses={}
var rest_points={}
var displayed_pose=""
var profile={}
var role="mark"
var mode="idle"
var grounded=true
var motion=Vector2.ZERO
var cadence=0.0
var age=0.0
var event_age=9.0
var landing_age=9.0
var landing_force=0.0
var delight=0.0
var frozen=false
var playback_rate=1.0
@export var manual_pose=false
@export var show_points=false
@export var gameplay_actor=false
var reduced_motion=false
var blink_value=0.0
var applied_grounded=true
var base_vertices=PackedVector2Array()
var bone_weights={}
var face_material: ShaderMaterial
var markers={}
var emote=""
var emote_left=0.0
var channel_angles={}
var step_delta=1.0/60.0
var character3d
var _skin_pose_key=""

class RigOverlay extends Node2D:
	var rig
	func _draw():
		if not is_instance_valid(rig):return
		var colour=Color(1,.86,.42,.85)
		for chain in [["head","neck","hips"],["shoulder_near","elbow_near","wrist_near"],["shoulder_far","elbow_far","wrist_far"],["hips","knee_near","ankle_near","toe_near"],["hips","knee_far","ankle_far","toe_far"]]:
			var line=PackedVector2Array()
			for point in chain:line.append(rig.joint_position(point))
			draw_polyline(line,colour,2,true)
		for key in rig.rest_points:
			if key=="origin":continue
			var p=rig.joint_position(key);draw_circle(p,3,colour)
			if key in ["head","shoulder_near","elbow_near","wrist_near","hips","knee_near","ankle_near","eye_near","mouth"]:
				draw_string(ThemeDB.fallback_font,p+Vector2(5,-5),key,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff4d7"))

func _ready():
	if profiles.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rigs/character_points.json"));profiles=data.profiles
	tuning=load("res://resources/character_motion.tres")
	skeleton=Skeleton2D.new();skeleton.name="Skeleton2D";add_child(skeleton)
	for link in LINKS:
		var bone=Bone2D.new();bone.name=link[0];bone.set_autocalculate_length_and_angle(false);bone.set_length(24);bone.rest=Transform2D.IDENTITY
		if link[1].is_empty():skeleton.add_child(bone)
		else:bones[link[1]].add_child(bone)
		bones[link[0]]=bone
	mesh=Polygon2D.new();mesh.name="PaintedMesh";add_child(mesh);mesh.skeleton=NodePath("../Skeleton2D")
	face_material=ShaderMaterial.new();face_material.shader=load("res://shaders/character_face.gdshader");mesh.material=face_material
	make_grid()
	overlay=RigOverlay.new();overlay.name="AnimationPoints";overlay.rig=self;overlay.z_index=5;add_child(overlay);overlay.hide()
	for key in ["head","neck","shoulder_near","elbow_near","wrist_near","shoulder_far","elbow_far","wrist_far","hips","knee_near","ankle_near","toe_near","knee_far","ankle_far","toe_far","eye_near","eye_far","brow_near","brow_far","mouth","crown","leaf_near","leaf_far","coat"]:
		var point=Marker2D.new();point.name=key;overlay.add_child(point);markers[key]=point
	character3d=load("res://scripts/characters/character_presenter_3d.gd").new()
	character3d.owner_actor=self;add_child(character3d)
	sync_pose()

func make_grid():
	var uv=PackedVector2Array();var faces=[]
	for row in range(ROWS+1):
		for col in range(COLS+1):
			var p=Vector2(float(col)/COLS*512,float(row)/ROWS*640);uv.append(p);base_vertices.append(p-ANCHOR)
	for row in range(ROWS):
		for col in range(COLS):
			var i=row*(COLS+1)+col
			faces.append(PackedInt32Array([i,i+1,i+COLS+1]));faces.append(PackedInt32Array([i+1,i+COLS+2,i+COLS+1]))
	mesh.polygon=base_vertices;mesh.uv=uv;mesh.polygons=faces

func sync_pose():
	if texture==null:return
	var id=texture.resource_path.get_file().get_basename()
	if id==displayed_pose:
		update_presentation()
		return
	displayed_pose=id
	if not profiles.has(id):
		profile={};mesh.hide();overlay.hide();self_modulate.a=1
		if is_instance_valid(character3d):character3d.configure(role,false)
		return
	mesh.texture=texture;face_material.set_shader_parameter("face_paint",texture);profile=profiles[id];role=profile.role
	update_presentation()
	rest_points={"origin":Vector2.ZERO}
	for key in profile.points:rest_points[key]=Vector2(profile.points[key][0],profile.points[key][1])-ANCHOR
	rest_globals={}
	for link in LINKS:
		var position: Vector2=rest_points[link[2]]
		var parent_position=Vector2.ZERO if link[1].is_empty() else rest_globals[link[1]].origin
		var bone=bones[link[0]];bone.transform=Transform2D(0,position-parent_position);bone.rest=bone.transform
		rest_globals[link[0]]=Transform2D(0,position)
	if not is_instance_valid(character3d) or not character3d.active:apply_skin()
	var a=profile.eyes[0];var b=profile.eyes[1];var mouth=profile.mouth
	face_material.set_shader_parameter("eye_near",Vector4(a[0]/512.0,a[1]/640.0,a[2]/512.0,a[3]/640.0))
	face_material.set_shader_parameter("eye_far",Vector4(b[0]/512.0,b[1]/640.0,b[2]/512.0,b[3]/640.0))
	face_material.set_shader_parameter("mouth",Vector4(mouth[0]/512.0,mouth[1]/640.0,mouth[2]/512.0,mouth[3]/640.0))

func update_presentation():
	# Keep the complete source painting available, independently of accessibility.
	# The studio always exposes the articulated performance for inspection.
	var painted=gameplay_actor and bool(Progress.settings.get("painted_characters",true))
	var use_3d=bool(Progress.settings.get("characters_3d",true)) and not profile.is_empty()
	if is_instance_valid(character3d):character3d.configure(role,use_3d)
	mesh.visible=not use_3d and not painted and not profile.is_empty()
	self_modulate.a=0.0 if use_3d else 1.0 if painted or profile.is_empty() else 0.0

func point(key):return rest_points[key]+ANCHOR
func capsule(p,a,b,radius):
	var delta=b-a;var t=clampf((p-a).dot(delta)/maxf(1.0,delta.length_squared()),0,1)
	return pow(maxf(0,1-p.distance_to(a+delta*t)/radius),2)
func disc(p,center,radius):return pow(maxf(0,1-p.distance_to(center)/radius),2)
func weights_at(p,pin):
	var weights={"Hip":.3}
	var h=point("head");var radius=Vector2(profile.head_radius[0],profile.head_radius[1]);var head_distance=((p-h)/radius).length()
	weights.Head=clampf((1.2-head_distance)*3.0,0,1)*1.9
	for side in ["Near","Far"]:
		var suffix="near" if side=="Near" else "far"
		weights["Shoulder"+side]=capsule(p,point("shoulder_"+suffix),point("elbow_"+suffix),46)*1.8
		weights["Elbow"+side]=capsule(p,point("elbow_"+suffix),point("wrist_"+suffix),38)*2.0
		weights["Wrist"+side]=disc(p,point("wrist_"+suffix),32)*1.5
		weights["Thigh"+side]=capsule(p,point("hips"),point("knee_"+suffix),42)*1.5
		weights["Knee"+side]=capsule(p,point("knee_"+suffix),point("ankle_"+suffix),35)*1.8
		weights["Ankle"+side]=capsule(p,point("ankle_"+suffix),point("toe_"+suffix),32)*1.6
		weights["Toe"+side]=disc(p,point("toe_"+suffix),26)*.6
	weights.Crown=disc(p,point("crown"),65)*.5
	if role=="bark":
		weights.LeafNear=disc(p,point("leaf_near"),47)*.65;weights.LeafFar=disc(p,point("leaf_far"),47)*.65
	else:weights.Coat=disc(p,point("coat"),65)*.5
	var names=weights.keys();names.sort_custom(func(a,b):return weights[a]>weights[b]);var result={};var total=0.0
	for n in range(mini(4,names.size())):result[names[n]]=weights[names[n]];total+=weights[names[n]]
	for key in result:result[key]/=total
	var locked=smoothstep(565.0,610.0,p.y) if pin else 0.0
	if locked>0:
		for key in result:result[key]*=1-locked
		result.FootLock=locked
		# Native polygon skinning keeps the strongest four influences.
		names=result.keys();names.sort_custom(func(a,b):return result[a]>result[b]);var trimmed={};total=0
		for n in range(mini(4,names.size())):trimmed[names[n]]=result[names[n]];total+=result[names[n]]
		for key in trimmed:trimmed[key]/=total
		return trimmed
	return result
func apply_skin():
	var key=displayed_pose+("_ground" if grounded else "_air")
	_skin_pose_key=key
	if not skin_cache.has(key):
		var arrays={}
		for link in LINKS:
			var values=PackedFloat32Array();values.resize(base_vertices.size());arrays[link[0]]=values
		for n in range(base_vertices.size()):
			var weights=weights_at(base_vertices[n]+ANCHOR,grounded)
			for bone in weights:arrays[bone][n]=weights[bone]
		skin_cache[key]=arrays
	bone_weights=skin_cache[key];mesh.clear_bones()
	for link in LINKS:
		if bone_weights[link[0]].count(0.0)!=base_vertices.size():mesh.add_bone(skeleton.get_path_to(bones[link[0]]),bone_weights[link[0]])
	applied_grounded=grounded

func drive(next_mode,is_grounded,velocity=Vector2.ZERO,gait=0.0):
	mode=next_mode;grounded=is_grounded;motion=velocity;cadence=gait
func pulse(name,seconds=.55):
	emote=name;emote_left=seconds;event_age=0
	if is_instance_valid(character3d):character3d.pulse(name,seconds)
func land(strength):
	landing_age=0;landing_force=strength
	if is_instance_valid(character3d):character3d.land(strength)
func reset_motion():
	event_age=9;landing_age=9;emote_left=0;delight=0;channel_angles.clear();mode="idle";motion=Vector2.ZERO
	if is_instance_valid(character3d):character3d.reset_motion()
	if is_instance_valid(skeleton):
		for bone in bones.values():bone.apply_rest()
func _process(delta):
	var raw_delta=delta
	delta*=playback_rate
	step_delta=minf(delta,.05)
	sync_pose()
	if profile.is_empty():return
	if not is_visible_in_tree():
		if is_instance_valid(character3d):character3d.stop_rendering()
		return
	reduced_motion=bool(Progress.settings.reduced_motion)
	if not frozen:
		age+=delta*tuning.tempo;event_age+=delta;landing_age+=delta;emote_left=maxf(0,emote_left-delta)
	if is_instance_valid(character3d) and character3d.active:
		character3d.step(raw_delta)
		overlay.visible=show_points
		if show_points:
			for key in markers:markers[key].position=joint_position(key)
			overlay.queue_redraw()
		return
	if applied_grounded!=grounded or _skin_pose_key!=displayed_pose+("_ground" if grounded else "_air"):apply_skin()
	if reduced_motion:
		channel_angles.clear()
		for bone in bones.values():bone.apply_rest()
	elif not frozen and not manual_pose:animate()
	update_face()
	global_poses={}
	for link in LINKS:global_poses[link[0]]=bones[link[0]].transform if link[1].is_empty() else global_poses[link[1]]*bones[link[0]].transform
	overlay.visible=show_points
	if show_points:
		for key in markers:markers[key].position=joint_position(key)
		overlay.queue_redraw()

func animate():
	for bone in bones.values():bone.apply_rest()
	var active=mode
	if emote_left>0 and mode in ["idle","walk","run"]:active=emote
	if displayed_pose.ends_with("_cheer"):active="celebrate"
	elif displayed_pose.ends_with("_hint") and active=="idle":active="hint"
	if profile.get("turnaround",false):active="idle"
	var gait=cadence if absf(motion.x)>10 else age*8
	var moving=active in ["walk","run"]
	var spring=active in ["spring_contact","spring_release","anticipate"]
	var speed=clampf(absf(motion.x)/260,0,1)
	var body=sin(age*2.1)*.008
	var head=sin(age*1.7+.4)*.014
	var arm=sin(gait)*(.035 if active=="walk" else .055) if moving else 0.0
	var knee=sin(gait)*.055 if moving else 0.0
	var squash=maxf(0,1-landing_age/.30)*landing_force
	if moving:body=.014*speed;head=-body*.7;body+=sin(gait*2)*.006
	if active=="jump":
		body=-clampf(motion.y/15000.0,-.035,.035);head=-body*.4;arm=sin(age*7)*.065-clampf(motion.y/10000.0,-.05,.05);knee=-.055
	if active=="anticipate":body=-.018;head=.015;arm=-.06;knee=.025
	if active=="spring_contact":body=.025;head=.025;arm=.04;knee=.08
	if active=="spring_release":body=-.025;head=-.018;arm=-.16+sin(age*12)*.04;knee=-.08
	if active in ["celebrate","delight"]:body=sin(age*6)*.018;head=sin(age*5)*.035;arm=sin(age*8)*.13;knee=sin(age*6)*.04
	if active in ["talk","hint"]:head=sin(age*4)*.025;arm=sin(age*3)*.025
	if profile.prop_locked:arm*=.12
	bones.Hip.rotation=body; bones.Hip.position.y+=sin(age*2.1)*1.6+sin(gait*2)*1.8*float(moving)+squash*3
	bones.Head.rotation=head*tuning.head
	bones.ShoulderNear.rotation=arm*tuning.arms;bones.ShoulderFar.rotation=-arm*.75*tuning.arms
	bones.ElbowNear.rotation=-arm*.60*tuning.arms;bones.ElbowFar.rotation=arm*.6*tuning.arms
	var hand_motion=.12 if profile.prop_locked else 1.0
	bones.WristNear.rotation=sin(age*5)*.018*tuning.arms*hand_motion;bones.WristFar.rotation=-sin(age*5+.4)*.018*tuning.arms*hand_motion
	bones.ThighNear.rotation=knee*.35*tuning.legs;bones.ThighFar.rotation=-knee*.3*tuning.legs
	bones.KneeNear.rotation=(knee+squash*.06)*tuning.legs;bones.KneeFar.rotation=(-knee+squash*.05)*tuning.legs
	if not grounded:
		bones.AnkleNear.rotation=-knee*.6*tuning.legs;bones.AnkleFar.rotation=knee*.5*tuning.legs
		bones.ToeNear.rotation=sin(age*6)*.035*tuning.legs;bones.ToeFar.rotation=-sin(age*6+.7)*.035*tuning.legs
	bones.Crown.rotation=sin(age*3.1-0.6)*.035*tuning.follow_through
	bones.Coat.rotation=(-body+sin(age*4)*.015)*tuning.follow_through
	if role=="bark":
		var leaf_motion=.07 if spring else .035
		bones.LeafNear.rotation=sin(age*4.8)*leaf_motion*tuning.follow_through;bones.LeafFar.rotation=sin(age*4.2+1)*leaf_motion*tuning.follow_through
	var phase=fmod(age+(2.2 if role=="bark" else 1.0),4.3)
	blink_value=(sin(phase/.17*PI) if phase<.17 else 0.0) if tuning.blinks and not spring and active!="jump" else 0.0
	if profile.closed_eyes:blink_value=0
	bones.EyeNear.scale.y=maxf(.03,1-blink_value);bones.EyeFar.scale.y=maxf(.03,1-blink_value*.98)
	var talk=active in ["talk","hint"]
	bones.Mouth.scale.y=1+maxf(0,sin(age*11))*.20*tuning.face*float(talk)
	bones.BrowNear.position.y-=maxf(0,sin(age*2.3))*.9*tuning.face;bones.BrowFar.position.y-=maxf(0,sin(age*2.3+.2))*.7*tuning.face
	bones.EyeNear.position.x+=sin(age*.7)*.45*tuning.face;bones.EyeFar.position.x+=sin(age*.7)*.35*tuning.face

	var response=1-exp(-step_delta*22)
	for key in bones:
		var target: float=bones[key].rotation
		channel_angles[key]=lerp_angle(float(channel_angles.get(key,0.0)),target,response)
		bones[key].rotation=channel_angles[key]

func update_face():
	var enabled=profile.face_enabled and not reduced_motion and tuning.face>0
	face_material.set_shader_parameter("face_enabled",enabled)
	face_material.set_shader_parameter("blink_near",1-bones.EyeNear.scale.y);face_material.set_shader_parameter("blink_far",1-bones.EyeFar.scale.y)
	face_material.set_shader_parameter("gaze_near",(bones.EyeNear.position-bones.EyeNear.rest.origin)/CANVAS)
	face_material.set_shader_parameter("gaze_far",(bones.EyeFar.position-bones.EyeFar.rest.origin)/CANVAS)
	face_material.set_shader_parameter("jaw_scale",bones.Mouth.scale.y)
	face_material.set_shader_parameter("brow_near",(bones.BrowNear.rest.origin.y-bones.BrowNear.position.y)/640.0)
	face_material.set_shader_parameter("brow_far",(bones.BrowFar.rest.origin.y-bones.BrowFar.position.y)/640.0)
func joint_position(key):
	if is_instance_valid(character3d) and character3d.active:return character3d.projected_joint(key)
	if not rest_points.has(key):return Vector2.ZERO
	if gameplay_actor and bool(Progress.settings.get("painted_characters",true)):return rest_points[key]
	var original: Vector2=rest_points[key];var weights=weights_at(original+ANCHOR,grounded);var result=Vector2.ZERO
	for bone in weights:
		if global_poses.has(bone):result+=(global_poses[bone]*rest_globals[bone].affine_inverse()*original)*weights[bone]
	return result
