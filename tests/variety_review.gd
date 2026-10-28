extends Node
var game
var passed=0
var failures=[]
func check(ok,label):
	if ok:passed+=1;print("PASS: "+label)
	else:failures.append(label);push_error("FAIL: "+label)
func ticks(n=2):
	for i in range(n):await get_tree().physics_frame
func key(code,down):
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e)
func _ready():call_deferred("run")
func run():
	await ticks();Mega.enabled=false;Mega.reset(false);Mega.prefs.calm=false;Progress.save_enabled=false
	game=load("res://scenes/mega.tscn").instantiate();add_child(game);await ticks(4)
	for i in range(3):
		game.load_level(i);await ticks(8)
		check(650-game.campus.top==[4410,5400,7080][i],"Level "+str(i+1)+" has triple-height ascent")
		check(game.campus.branches.size()==3 and game.campus.pickups.size()==25,"Three nooks and 24 leaves plus Bark token")
		check(game.campus.leaf_shelves[-1]==game.campus.RISES[i].size()-1,"Discoveries extend all the way to the summit")
		var kinds={}
		for l in game.campus.ledges:kinds[l.kind]=true
		check(kinds.size()==6,"Every climb includes six painted platform materials")
		check(game.campus.enemies.size()>=4,"Each climb has multiple dodge encounters")
		check(game.campus.scenery.top<=game.campus.top-760,"Scenery extends beyond the summit camera")
		var e=game.campus.enemies[0]
		game.pause_game();var before=e.position;var time=e.age;var grace=game.campus.enemy_grace;await ticks(30)
		check(e.position==before and e.age==time and game.campus.enemy_grace==grace,"Pause freezes patrols and recovery timers")
		game.close();await ticks(6);check(e.age>time,"Patrol resumes after pause")
		# A bump returns to the last landed shelf, preserving the higher-level quest state.
		Mega.runs[i].checkpoint=1;Mega.runs[i].leaves=range(24);Mega.runs[i].quest=true;Mega.runs[i].token=true
		game.campus.refresh()
		var safe=Vector2(game.campus.platforms[2].get_center().x,game.campus.platforms[2].position.y-3)
		game.place_player(safe);game.campus.last_safe=safe;game.campus.safe_shelf=3;game.last_shelf=3
		var progress=JSON.stringify(Mega.runs[i]);game.campus.enemy_grace=0
		game.player.position=e.position+Vector2(0,20);game.player.velocity=Vector2.ZERO;await ticks(3)
		check(game.player.position.distance_to(safe)<10 and game.last_shelf==3,"Contact returns to the nearby safe shelf")
		check(JSON.stringify(Mega.runs[i])==progress,"Bumps preserve every quest item and collectible")
		check(game.campus.enemy_grace>1,"Bump recovery grants a generous grace period")
		game.player.position=e.position+Vector2(0,20);game.player.velocity=Vector2.ZERO;await ticks(3)
		check(game.player.position.distance_to(safe)>80,"Grace prevents immediate repeated recovery")
		game.retry();await ticks(8)
		check(game.player.is_on_floor() and game.player.position.distance_to(Vector2(game.campus.platforms[1].get_center().x,game.campus.platforms[1].position.y))<4,"Manual checkpoint returns to the saved rest shelf")
		Mega.prefs.calm=true;game.campus.enemy_grace=0;game.player.position=e.position+Vector2(0,20);game.player.velocity=Vector2.ZERO;await ticks(4)
		check(game.player.position.distance_to(safe)>80 and game.campus.enemy_grace==0,"Calm climb permits harmless contact")
		Mega.prefs.calm=false;game.player.position=e.position+Vector2(-55,20);game.player.velocity=Vector2.ZERO;game.player.reset_jumps();game.jump();game.fingers[-1]="right";await ticks(14);game.fingers.clear()
		check(game.player.position.y<e.position.y-50 and game.campus.enemy_grace==0,"Jumping past a pest avoids the encounter")
		var qpos=game.campus.quest.sprite.position;game.fingers[-1]="left";await ticks(8);game.fingers.clear()
		check(game.campus.quest.sprite.position==qpos and game.campus.scenery.position==Vector2.ZERO,"Quest art and scenery stay in world space")
		for enemy in game.campus.enemies:check(not enemy.tip().is_empty(),"Every pest offers a practical dodge tip")
		for b in game.campus.branches:
			game.player.position=Vector2(b.rect.get_center().x,b.rect.position.y-1);game.player.velocity=Vector2.ZERO;await ticks(8);game.hint()
			check(String(game.dialogue[0]).contains("Return to shelf "+str(b.return_index+1)),"Each nook hint directs back to its parent shelf")
			game.end_dialogue()
		var cp=[23,25,31][i];Mega.runs[i].checkpoint=cp;game.load_level(i);await ticks(12)
		check(game.player.is_on_floor() and absf(game.player.position.y-game.campus.platforms[cp].position.y)<5,"Loading an upper checkpoint starts on its landing surface")
	key(KEY_D,true);await ticks(8);check(game.player.velocity.x>150,"Physical keyboard movement works through the input map");key(KEY_D,false);await ticks(4)
	key(KEY_SPACE,true);await ticks(2);key(KEY_SPACE,false);await ticks(24);key(KEY_SPACE,true);await ticks(2);key(KEY_SPACE,false)
	check(game.player.jumps_used==2 and game.spring_age<.1,"Physical Space input launches the Bark spring")
	var image=load("res://assets/variety/platform_atlas.png").get_image()
	check(image.get_size()==Vector2i(1536,1024) and image.get_pixel(0,0).a==0,"Painted atlas imports with real transparency")
	game.journal();await ticks(2);check(game.panel.size.y==510,"Notebook provides room for progress and hints");game.close()
	game.settings(game.close);await ticks(2);var calm=game.panel.get_node("CalmClimb");calm.button_pressed=true
	check(Mega.prefs.calm,"Calm-climb control updates the preference");game.close();Mega.prefs.calm=false
	await test_saves()
	game.effects.stop();game.effects.stream=null;await game.soundscape.drain();game.queue_free();await ticks(4)
	print("VARIETY RESULT: ",passed," passed; ",failures.size()," failed");get_tree().quit(0 if failures.is_empty() else 1)
func write_save(data):
	var f=FileAccess.open(Mega.PATH,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
func test_saves():
	var original={}
	for path in [Mega.PATH,Mega.PATH+".bak",Mega.PATH+".tmp"]:
		if FileAccess.file_exists(path):original[path]=FileAccess.get_file_as_bytes(path)
	var legacy={"version":1,"unlocked":2,"current":1,"intro_done":true,"runs":[{"checkpoint":5,"leaves":[0,7],"quest":true,"token":true},{"checkpoint":7,"leaves":[],"quest":false,"token":false}],"best":[]}
	write_save(legacy);Mega._ready()
	check(Mega.unlocked==2 and Mega.runs[0].quest and Mega.runs[0].checkpoint==5 and Mega.runs[0].leaves==[0,7],"Version 1 saves retain progress")
	Mega.runs[2].checkpoint=31;Mega.runs[2].leaves=[0,20,23];Mega.prefs.calm=true;Mega.enabled=true
	check(Mega.save(),"Atomic progress save succeeds")
	Mega._ready();check(Mega.runs[2].checkpoint==31 and Mega.runs[2].leaves==[0,20,23] and Mega.prefs.calm,"Upper checkpoints, discoveries and calm mode reload")
	var f=FileAccess.open(Mega.PATH,FileAccess.WRITE);f.store_string("{interrupted");f.close();Mega._ready()
	check(Mega.recovered_backup and Mega.runs[0].checkpoint==5 and Mega.unlocked==2,"Interrupted primary save recovers the valid backup")
	write_save({"version":2,"unlocked":999,"current":999,"runs":[{"checkpoint":9999,"leaves":[0,0,5.0,23,999,"3",null,true,-1],"quest":"yes"}],"prefs":{"calm":"yes"}});Mega._ready()
	check(Mega.unlocked==3 and Mega.current==2 and Mega.runs[0].checkpoint==23,"Malformed numeric progress is bounded safely")
	check(Mega.runs[0].leaves==[0,5,23] and not Mega.prefs.calm and not Mega.runs[0].quest,"Invalid and duplicate discoveries are rejected")
	Mega.prefs.calm=true;Mega.reset(false);check(Mega.prefs.calm,"New adventures preserve accessibility preferences")
	# Restore all prior files, including the new backup, after exercising save recovery.
	for path in [Mega.PATH,Mega.PATH+".bak",Mega.PATH+".tmp"]:
		if original.has(path):f=FileAccess.open(path,FileAccess.WRITE);f.store_buffer(original[path]);f.close()
		elif FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	Mega.enabled=false
