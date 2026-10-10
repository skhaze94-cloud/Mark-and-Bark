extends Node
var game
var passed=0
var failures=[]
var screenshots=false
func capture(label):
	if not screenshots:return
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://test_output/jump_"+label+".png")
func check(ok,label):
	if ok:passed+=1;print("PASS: "+label)
	else:failures.append(label);push_error("FAIL: "+label)
func ticks(n=1):
	for i in range(n):await get_tree().physics_frame
func _ready():call_deferred("run")
func run():
	await ticks(2)
	screenshots="--screenshots" in OS.get_cmdline_user_args()
	Mega.enabled=false;Mega.reset(false);Progress.save_enabled=false;Progress.settings.reduced_motion=false
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(4)
	game.load_level(0);await ticks(8)
	for direction in [-1,1]:
		game.retry();await ticks(8);game.player.facing=direction
		game.jump();await ticks(24)
		check(game.campus.bark.position.distance_to(game.player.position+Vector2(0,60))<45,"Bark anticipates the spring, facing "+str(direction))
		await capture("ready_"+str(direction))
		var before=game.campus.bark.position
		game.jumped(true)
		check(game.campus.bark.position==before,"Requesting spring never teleports Bark")
		# Use the real input path to verify launch and track the entire recovery.
		game.jump();await ticks(2)
		check(game.player.velocity.y<-500 and game.player.jumps_used==2,"Spring impulse remains immediate and full strength")
		await capture("contact_"+str(direction))
		var largest=0.0
		var largest_scale=0.0
		var prior=game.campus.bark.position
		var prior_scale=game.campus.bark.scale.abs()
		for i in range(42):
			await ticks()
			largest=maxf(largest,prior.distance_to(game.campus.bark.position))
			largest_scale=maxf(largest_scale,prior_scale.distance_to(game.campus.bark.scale.abs()))
			prior=game.campus.bark.position;prior_scale=game.campus.bark.scale.abs()
			if i in [5,13,25]:await capture("phase_"+str(i)+"_"+str(direction))
		check(largest<35,"Contact, release and recovery stay continuous")
		check(largest_scale<.018,"Bark's squash and stretch settle smoothly")
	game.retry();await ticks(8);game.jump();await ticks(24);game.jump();await ticks(3)
	var position_before=game.campus.bark.position;var age=game.spring_age
	game.pause_game();await ticks(20)
	check(game.campus.bark.position==position_before and game.spring_age==age,"Pause freezes the teamwork animation")
	game.close();await ticks(3)
	check(game.spring_age>age,"Resuming continues the launch")
	game.retry();await ticks(8);Progress.settings.reduced_motion=true;game.jump();await ticks(24);game.jump();await ticks(3)
	check(game.campus.bark.scale==Vector2.ONE*.2 and game.campus.bark.rotation==0,"Reduced motion removes squash and lean")
	Progress.settings.reduced_motion=false
	game.retry();await ticks(8);game.jump();await ticks(24);game.jump();await ticks(2);game.retry()
	check(game.player.pose_lock<=0 and game.player.sprite.modulate.a==1 and game.campus.bark.scale==Vector2(.2*game.player.facing,.2),"Checkpoint clears contact pose and squash immediately")
	game.retry();await ticks(8);game.jump();await ticks(2);game.jump();await ticks(2)
	check(game.player.jumps_used==2 and game.player.velocity.y<-500,"Rapid double tap launches immediately")
	game.jump();await ticks(2)
	check(game.player.jumps_used==2,"Rapid third tap cannot add another spring")
	game.retry();await ticks(8);game.player.facing=1;game.jump();await ticks(24)
	game.fingers[-1]="left";game.jump();await ticks(2)
	check(game.spring_facing==-1,"Reversing on the launch frame uses the new direction")
	var release_speed=game.spring_release_velocity
	game.fingers.clear();game.fingers[-2]="right";await ticks(12)
	check(game.spring_release_velocity==release_speed and game.player.velocity.x>0,"Midair steering stays responsive without reversing Bark's release")
	game.fingers.clear();game.retry();await ticks(8)
	var ceiling=StaticBody2D.new();var collision=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(220,16);collision.shape=shape;ceiling.add_child(collision);ceiling.position=game.player.position+Vector2(0,-110);game.campus.add_child(ceiling)
	await ticks(2);game.jump();await ticks(2);game.jump();await ticks(15)
	check(game.player.is_on_floor() and not game.player.spring_contact and game.spring_age>=.45,"A low ceiling landing cancels airborne choreography")
	check(game.player.pose_lock<=0 and game.player.sprite.texture==Art.tex("young_actions_idle"),"Early landing restores Mark's standing pose")
	ceiling.queue_free();await ticks(2)
	var shelf=game.campus.platforms[0]
	game.player.position=Vector2(shelf.position.x+8,shelf.position.y-1);game.player.velocity=Vector2.ZERO;game.player.reset_jumps();await ticks(90)
	check(game.campus.bark.position.x>=shelf.position.x and absf(game.campus.bark.position.y-shelf.position.y)<2,"Bark rests on Mark's shelf at its edge")
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4)
	print("JUMP RESULT: ",passed," passed; ",failures.size()," failed")
	get_tree().quit(0 if failures.is_empty() else 1)
