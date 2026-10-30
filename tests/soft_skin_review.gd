extends Node
## Regression checks for weighted surfaces, pose attachment and accessibility.
var passed=0
var failures=0
func check(ok,message):
	if ok:passed+=1
	else:failures+=1;push_error(message)

func deformed(rig,arrays,index):
	var point=Vector3.ZERO
	for slot in range(4):
		var bone=arrays[Mesh.ARRAY_BONES][index*4+slot]
		var weight=arrays[Mesh.ARRAY_WEIGHTS][index*4+slot]
		point+=(rig.get_bone_global_pose(bone)*rig.bindings.get_bind_pose(bone)*arrays[Mesh.ARRAY_VERTEX][index])*weight
	return point

func _ready():
	Progress.save_enabled=false;Mega.enabled=false
	for id in ["young_actions_idle","bark_actions_idle"]:
		var actor=Art.character(id);add_child(actor);actor.set_process(false)
		var presenter=actor.character3d
		presenter.configure("mark" if id.begins_with("young") else "bark",true)
		var model=presenter.model;var rig=model.soft_skin;var perf=presenter.performance
		check(rig is Skeleton3D and rig.get_bone_count()>=12,"A real skeleton drives both friends")
		check(rig.bindings.get_bind_count()==rig.get_bone_count(),"Every bone has its inverse bind")
		var limb_count=0
		for part in rig.surfaces:
			var a=part.mesh.surface_get_arrays(0);var count=a[Mesh.ARRAY_VERTEX].size()
			var valid=a[Mesh.ARRAY_BONES].size()==count*4 and a[Mesh.ARRAY_WEIGHTS].size()==count*4
			var blended=false
			for v in range(count):
				var total=0.0
				for slot in range(4):
					var w=a[Mesh.ARRAY_WEIGHTS][v*4+slot]
					total+=w
					valid=valid and w>=0 and a[Mesh.ARRAY_BONES][v*4+slot]<rig.get_bone_count()
					if w>.05 and w<.95:blended=true
				# RenderingServer packs weights into 16-bit normalized components.
				valid=valid and absf(total-1.0)<.00004 and a[Mesh.ARRAY_VERTEX][v].is_finite()
			check(valid,"All vertex weights are finite, nonnegative and normalized")
			if str(part.name).begins_with("Continuous") or str(part.name).begins_with("Living"):
				limb_count+=1
				check(blended,"Each limb has a gradual weighted joint region")
				# The circumference seam must remain coincident under arbitrary poses.
				var seam_ok=true
				for row in range(33):
					seam_ok=seam_ok and a[0][row*25].distance_to(a[0][row*25+24])<.00001
				check(seam_ok,"Circumference seam closes at every ring")
		check(limb_count==4,"All four limbs are continuous weighted surfaces")
		var scene_count=rig.get_child_count()
		for pose in ["idle","wave","jump","notebook","thinking","laugh","delight"]:
			perf.drive(pose,pose!="jump",Vector2(0,-260) if pose=="jump" else Vector2.ZERO)
			for frame in range(20):perf.advance(1.0/60)
			var aligned=true
			for b in range(rig.get_bone_count()):
				aligned=aligned and rig.get_bone_global_pose(b).is_equal_approx(rig.relative(rig.sources[b]))
			check(aligned,"Skeleton follows final solved pivots during "+pose)
			var finite=true
			for part in rig.surfaces:
				var a=part.mesh.surface_get_arrays(0)
				for v in range(0,a[0].size(),11):finite=finite and deformed(rig,a,v).is_finite()
			check(finite,"Deformation stays finite during "+pose)
		var before=[]
		for b in range(rig.get_bone_count()):before.append(rig.get_bone_pose(b))
		perf.frozen=true;perf.advance(.1)
		var frozen=true
		for b in range(rig.get_bone_count()):frozen=frozen and before[b]==rig.get_bone_pose(b)
		check(frozen,"Pause freezes all skinned bone transforms")
		check(scene_count==rig.get_child_count(),"Pose changes allocate no new skin surfaces")
		if DisplayServer.get_name()!="headless":
			# Ask the native renderer to bake its actual skinning result; compare
			# selected vertices with an independent CPU evaluation of the binds.
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var part=rig.surfaces[0]
			var baked=part.bake_mesh_from_current_skeleton_pose()
			var actual=baked.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var source=part.mesh.surface_get_arrays(0)
			var matches=actual.size()==source[0].size()
			for v in range(0,actual.size(),13):
				matches=matches and actual[v].distance_to(deformed(rig,source,v))<.002
			check(matches,"Native baked vertices match the weighted posed skeleton")
		perf.frozen=false;perf.reduced_motion=true;perf.advance(.1)
		presenter.finishing.advance(.1,Vector2(260,0),false,true)
		check(presenter.finishing.tail_bend==0 and presenter.finishing.tail_velocity==0,"Reduced motion removes scarf overshoot")
		actor.free()
	print("SOFT SKIN RESULT: ",passed," passed; ",failures," failed")
	get_tree().quit(0 if failures==0 else 1)
