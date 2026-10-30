extends SceneTree
## Native character review. Run with -- --baseline to capture the prior release.
var directory="res://test_output/character_showcase"
var actors=[]
var board: Node2D
var headline: Label
func _initialize():call_deferred("run")
func run():
 root.get_node("Progress").save_enabled=false;root.get_node("Mega").enabled=false
 root.get_node("Progress").settings.characters_3d=true
 if current_scene:current_scene.queue_free()
 board=Node2D.new();root.add_child(board)
 var bg=ColorRect.new();bg.color=Color("f6efdd");bg.size=Vector2(1280,720);board.add_child(bg)
 headline=Label.new();headline.position=Vector2(40,24);headline.add_theme_font_size_override("font_size",30);headline.add_theme_color_override("font_color",Color("304a53"));board.add_child(headline)
 for i in range(2):
  var actor=root.get_node("Art").character("young_actions_idle" if i==0 else "bark_actions_idle")
  actor.position=Vector2(420 if i==0 else 850,625);actor.scale=Vector2.ONE*(.9 if i==0 else 1.08);board.add_child(actor);actor.set_process(false);actors.append(actor)
 for i in 4:await process_frame
 DirAccess.make_dir_recursive_absolute(directory)
 var baseline="--baseline" in OS.get_cmdline_user_args()
 var tag="4.3" if baseline else "4.4"
 if "--movie" in OS.get_cmdline_user_args():
  await movie();quit();return
 for pose in ["idle","curious","uncertain","surprise","delight","wave","present","walk","jump","talk"]:
  for view in ["front","quarter"]:
   headline.text=tag+" · "+pose.capitalize()+" · "+view
   for actor in actors:
    actor.reset_motion();actor.frozen=false
    actor.drive(pose,pose!="jump",Vector2(150,-250) if pose=="jump" else Vector2(140,0) if pose=="walk" else Vector2.ZERO,.9)
    actor.character3d.inspection_yaw=-.48 if view=="front" else .18
    for i in 28:actor._process(1.0/60.0)
    actor.frozen=true;actor._process(0)
   for i in 3:await process_frame
   await RenderingServer.frame_post_draw
   for actor in actors:actor.character3d.viewport.get_texture().get_image().save_png(directory+"/"+tag+"_"+actor.role+"_"+pose+"_"+view+".png")
 quit()
func movie():
 for frame in range(288):
  var t=float(frame)/24.0
  var stage=int(t/2.0)
  var state=["idle","curious","surprise","present","laugh","delight"][mini(stage,5)]
  headline.text="SEAMLESS MOTION · "+["A quiet moment","What have you found?","Oh!","Look at this!","An excellent joke","Two very happy friends"][mini(stage,5)]
  for actor in actors:
   actor.frozen=false
   actor.drive("thinking" if state=="curious" and actor.role=="bark" else state,true)
   if stage==3 and frame%48==0:actor.character3d.greet_friend(1 if actor.role=="mark" else -1)
   actor._process(1.0/24.0)
  await process_frame
