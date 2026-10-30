extends Node
var passed=0
var failures=0
func check(ok,message):
 if ok:passed+=1
 else:failures+=1;push_error(message)
func _ready():
 Progress.save_enabled=false
 for id in ["young_actions_idle","bark_actions_idle"]:
  var actor=Art.character(id);add_child(actor)
  actor.position=Vector2(400,500)
  actor.character3d.configure("mark" if id.begins_with("young") else "bark",true)
  var f=actor.character3d.finishing
  check(f.motes.size()==6,"Each actor has six reusable flourishes")
  check(f.motes.all(func(m):return not m.visible),"Flourishes begin hidden")
  var count=f.get_child_count()
  f.celebrate();f.advance(.2,Vector2.ZERO,false,false)
  check(f.motes.all(func(m):return m.visible),"Celebration reveals flourishes")
  var age=f.flourish_age;var position=f.motes[0].position
  f.advance(.2,Vector2.ZERO,true,false)
  check(f.flourish_age==age and f.motes[0].position==position,"Pause freezes lifetime and position")
  f.advance(.2,Vector2.ZERO,false,true)
  check(f.motes.all(func(m):return not m.visible),"Reduced motion hides flourishes")
  f.celebrate();f.advance(1.3,Vector2.ZERO,false,false)
  check(f.motes.all(func(m):return not m.visible) and count==f.get_child_count(),"Flourishes expire without allocation")
  f.celebrate();f.advance(.1,Vector2.ZERO,false,false)
  f.advance(.1,Vector2.ZERO,true,true)
  check(f.motes.all(func(m):return not m.visible),"Reduced motion hides visible flecks even during pause")
  var performance=actor.character3d.performance
  performance.drive("idle",true);performance.advance(.1)
  var resting=performance.model.joints.shoulder_far.rotation
  performance.pulse("wave",1.0);performance.advance(.1)
  check(performance.active_state=="wave" and performance.model.joints.shoulder_far.rotation.distance_to(resting)>.3,"A greeting performs a visible articulated wave")
  check(performance.model.emotion=="wave","Event expression follows the greeting pose")
  performance.look_at_friend(1);performance.advance(.1)
  check(performance.gaze.x>0 and performance.model.joints.head.rotation.y>0,"Discovery glance directs eyes and head toward the friend")
  var remaining=performance.friend_left;performance.frozen=true;performance.advance(.1)
  check(performance.friend_left==remaining,"Pause freezes the shared glance")
  performance.frozen=false;performance.reduced_motion=true;performance.advance(.1)
  var held=performance.model.joints.wrist_far.rotation
  performance.advance(.1)
  check(performance.model.joints.wrist_far.rotation.is_equal_approx(held),"Reduced motion holds the greeting without oscillating")
  performance.reduced_motion=false
  for i in range(25):performance.advance(.1)
  check(performance.friend_left==0 and performance.active_state=="idle","Greeting and glance return to a calm idle")
  performance.drive("celebrate",true);performance.advance(.1)
  check(performance.smile>.8 and performance.mouth_open>.4,"Celebration has a distinct delighted expression")
  performance.reset_motion();performance.drive("surprise",true)
  performance.advance(.1)
  check(performance.active_state=="surprise" and performance.brow>.8,"Surprise has a clear raised-brow expression")
  for i in range(12):performance.advance(.1)
  check(performance.active_state=="curious","Surprise settles into curiosity without cycling")
  performance.reset_motion();performance.drive("idle",true)
  performance.share_discovery(1)
  performance.advance(.1)
  check(performance.active_state in ["spot","thinking"],"Shared discovery starts with noticing and thought")
  var discovery=performance.discovery_age
  performance.frozen=true;performance.advance(.1)
  check(performance.discovery_age==discovery,"Pause freezes the discovery sequence")
  performance.frozen=false
  for i in range(7):performance.advance(.1)
  check(performance.active_state in ["point","curious"],"Discovery points and leans before the glance")
  for i in range(7):performance.advance(.1)
  check(performance.active_state=="glance" and performance.gaze.x>0,"Both friends exchange a directed look")
  for i in range(9):performance.advance(.1)
  check(performance.active_state in ["present","delight"],"Discovery ends in presentation and delight")
  for i in range(12):performance.advance(.1)
  check(performance.active_state=="idle","Shared discovery returns to rest")
  performance.share_discovery(1);performance.reduced_motion=true;performance.advance(.1)
  check(performance.active_state in ["present","delight"],"Reduced motion gives a single held discovery pose")
  actor.free()
 print("PAINTED RESULT: ",passed," passed; ",failures," failed")
 get_tree().quit(0 if failures==0 else 1)
