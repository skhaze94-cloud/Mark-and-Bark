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
  actor.free()
 print("PAINTED RESULT: ",passed," passed; ",failures," failed")
 get_tree().quit(0 if failures==0 else 1)
