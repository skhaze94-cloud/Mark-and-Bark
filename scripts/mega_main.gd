extends Node2D
var campus
var player
var camera: Camera2D
var mode="title"
var busy=false
var panel: Panel
var hud: Control
var overlay: Control
var veil: ColorRect
var objective: Label
var counters: Label
var context: Label
var notice: Label
var touch_root: Control
var touch_mode=false
var fingers={}
var soundscape
var spring_age=9.0
var spring_anchor=Vector2.ZERO
var spring_contacts=0
var spring_facing=1
var spring_release_velocity=0.0
var dialogue=[]
var page=0
var dialogue_portrait: TextureRect
var dialogue_label: Label
var dialogue_done: Callable
var back: Callable
var clock=0.0
var notice_until=0.0
var quitting=false
var notice_back: Panel
var context_back: Panel
var objective_icon: TextureRect
var height_meter
var route_label: Label
var last_shelf=0
var travelling=false
var travel_veil: ColorRect
var result_open=false
var pickup_effects=[]
var ambient: CanvasModulate
var effects: AudioStreamPlayer
var sound_bank={}
var intro_ray
var hint_target=Vector2.ZERO
var hint_until=0.0
func _ready():
	for action in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E,KEY_ENTER],"hint":[KEY_H],"pause":[KEY_ESCAPE],"notebook":[KEY_N],"retry":[KEY_R]}:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E,KEY_ENTER],"hint":[KEY_H],"pause":[KEY_ESCAPE],"notebook":[KEY_N],"retry":[KEY_R]}[action]:
			var e=InputEventKey.new();e.physical_keycode=key;InputMap.action_add_event(action,e)
	campus=load("res://scripts/mega_level.gd").new();add_child(campus);campus.build(0)
	player=load("res://scripts/player.gd").new();add_child(player);player.right_bound=1600;player.position=Vector2(510,645);player.jumped.connect(jumped);player.landed.connect(landed);player.movement_finished.connect(update_bark_jump)
	camera=Camera2D.new();camera.position=Vector2(800,330);add_child(camera);camera.make_current()
	var canvas=CanvasLayer.new();canvas.layer=10;add_child(canvas)
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(hud)
	var head=card(hud,Rect2(20,16,1240,112),"203849")
	objective_icon=TextureRect.new();objective_icon.position=Vector2(18,14);objective_icon.size=Vector2(76,76);objective_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;objective_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;head.add_child(objective_icon)
	objective=text(head,"",Rect2(108,11,782,74),22,"fff3d3")
	height_meter=load("res://scripts/mega_meter.gd").new();height_meter.position=Vector2(108,91);height_meter.size=Vector2(777,8);height_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(height_meter)
	var route=card(hud,Rect2(20,141,205,73),"203849");route.mouse_filter=Control.MOUSE_FILTER_IGNORE
	route_label=text(route,"",Rect2(15,8,175,59),18,"fff3d3")
	counters=text(head,"",Rect2(920,15,165,85),17,"fff3d3")
	button(head,"Pause",Rect2(1098,27,120,55),pause_game)
	context_back=card(hud,Rect2(250,568,780,44),"203849");context_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;context_back.hide()
	context=text(hud,"",Rect2(260,575,760,40),20,"fff3d3");context.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;context.add_theme_color_override("font_shadow_color",Color("203849"));context.add_theme_constant_override("shadow_offset_y",2)
	notice_back=card(hud,Rect2(270,140,740,74),"203849");notice_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;notice_back.hide()
	notice=text(hud,"",Rect2(285,146,710,65),20,"fff3d3");notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.add_theme_color_override("font_shadow_color",Color("203849"));notice.add_theme_constant_override("shadow_offset_y",2)
	button(hud,"Notebook [N]",Rect2(20,620,230,70),journal)
	button(hud,"Notes",Rect2(1110,140,140,50),journal).name="TouchNotebook"
	button(hud,"Bark's hint [H]",Rect2(270,620,250,70),hint)
	button(hud,"Checkpoint [R]",Rect2(540,620,250,70),retry)
	touch_root=Control.new();touch_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(touch_root)
	var left=button(touch_root,"◀",Rect2(20,620,90,70),func():pass);left.button_down.connect(func():fingers[-1]="left");left.button_up.connect(func():fingers.erase(-1))
	var right=button(touch_root,"▶",Rect2(120,620,90,70),func():pass);right.button_down.connect(func():fingers[-2]="right");right.button_up.connect(func():fingers.erase(-2))
	button(touch_root,"Jump",Rect2(830,620,180,70),jump)
	button(touch_root,"Use",Rect2(1030,620,220,70),interact)
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(overlay)
	veil=ColorRect.new();veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);veil.color=Color(.07,.12,.15,.48);veil.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(veil);veil.hide()
	travel_veil=ColorRect.new();travel_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);travel_veil.color=Color("203849");travel_veil.hide();travel_veil.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(travel_veil);travel_veil.z_index=30
	ambient=CanvasModulate.new();ambient.color=Color("fff7e5");add_child(ambient)
	var grade=CanvasLayer.new();grade.layer=8;add_child(grade)
	var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=load("res://shaders/mega_finish.gdshader");shade.material=material;grade.add_child(shade)
	soundscape=load("res://scripts/soundscape.gd").new();soundscape.game=self;add_child(soundscape)
	effects=AudioStreamPlayer.new();add_child(effects)
	for id in ["jump","collect","success"]:
		var path="res://assets/"+id+".wav"
		if ResourceLoader.exists(path):sound_bank[id]=load(path)
	intro_ray=load("res://scripts/mega_ray.gd").new();intro_ray.game=self;add_child(intro_ray)
	get_tree().auto_accept_quit=false
	title()
func style(color):
	var s=StyleBoxFlat.new();s.bg_color=Color(color);s.border_color=Color("d7b164");s.set_border_width_all(2);s.set_corner_radius_all(18);s.shadow_color=Color(0,0,0,.24);s.shadow_size=8;return s
func card(parent,r,color="f5ecd6"):
	var c=Panel.new();c.position=r.position;c.size=r.size;c.add_theme_stylebox_override("panel",style(color));parent.add_child(c);return c
func text(parent,value,r,size=22,color="203849"):
	var l=Label.new();l.text=value;l.position=r.position;l.size=r.size;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_override("font",Art.font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color(color));parent.add_child(l);return l
func button(parent,value,r,action,primary=false):
	var b=Button.new();b.position=r.position;b.size=r.size;b.text=value;b.add_theme_font_override("font",Art.font);b.add_theme_font_size_override("font_size",20)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(state,Color("fff3d3") if primary else Color("203849"))
	b.add_theme_color_override("font_disabled_color",Color("625c4c"));b.add_theme_stylebox_override("disabled",style("ded9bb"))
	b.add_theme_stylebox_override("normal",style("203849" if primary else "fff3d3"));b.add_theme_stylebox_override("hover",style("436575" if primary else "e6d49f"));b.add_theme_stylebox_override("pressed",style("263e4b" if primary else "d7bc78"))
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("e7bf63");focus.set_border_width_all(4);focus.set_corner_radius_all(18);b.add_theme_stylebox_override("focus",focus)
	b.focus_mode=Control.FOCUS_NONE if parent==hud or parent==touch_root or parent.get_parent()==hud else Control.FOCUS_ALL
	parent.add_child(b);b.pressed.connect(action)
	if primary:b.grab_focus()
	return b
func close():
	if is_instance_valid(panel):panel.queue_free();overlay.remove_child(panel)
	panel=null;result_open=false;veil.hide();busy=false;player.suspended=false;player.enabled=mode=="campus";fingers.clear();dialogue_label=null;back=Callable()
func open(r):
	close();busy=true;player.suspended=true;player.enabled=false;player.axis=0;veil.show();panel=card(overlay,r);return panel
func title():
	mode="title";hud.hide();campus.build(0);player.position=Vector2(1130,645);player.velocity=Vector2.ZERO;camera.position=Vector2(800,420);ambient.color=Color("fff7e5");campus.bark.position=Vector2(1290,645);campus.bark.scale=Vector2.ONE*.35;campus.bark.texture=Art.tex("bark_actions_cheer");player.visual_scale=.42;player.sprite.scale=Vector2.ONE*.42;player.sprite.texture=Art.tex("young_actions_notebook");player.ghost.hide()
	var p=open(Rect2(55,60,710,600))
	text(p,"MARK & BARK",Rect2(35,25,640,65),42);text(p,"THE TINY, TALL ADVENTURE · 2.0",Rect2(35,97,640,40),23,"8a713f")
	text(p,"A shrinking ray. Three giant climbs.\nOne inventor and one spectacularly unhelpful tree.",Rect2(35,153,640,80),22)
	button(p,"Continue climb" if Mega.intro_done else "Start the adventure",Rect2(35,252,640,65),start,true)
	button(p,"Choose a level",Rect2(35,337,310,60),level_select)
	button(p,"Settings",Rect2(365,337,310,60),func():settings(title))
	button(p,"How to play",Rect2(35,417,310,60),func():how_to_play(title));button(p,"New adventure",Rect2(365,417,310,60),confirm_new)
	text(p,"Move: A/D or arrows · Jump: Space, then Space again\nUse: E · Hint: H · Notebook: N · Checkpoint: R · Pause: Esc",Rect2(35,505,640,70),17)
func confirm_new():
	var p=open(Rect2(320,200,640,310));back=title
	text(p,"A fresh tiny adventure?",Rect2(30,25,580,45),29);text(p,"Reset this three-level campaign and its best scores? Your original Big Idea chapter and sound settings stay saved.",Rect2(30,90,580,85),22)
	button(p,"Keep my adventure",Rect2(30,218,280,60),title,true);button(p,"Start fresh",Rect2(330,218,280,60),func():Mega.reset();start())
func start():
	load_level(Mega.current)
	if not Mega.intro_done:
		intro_ray.begin(func():say(["Mark|The ray says 'make your ideas smaller'. Is that helpful?","Bark|Press it twice. That's how you get twice as helpful!","Mark|Bark! We're tiny. The bookcase is a mountain!","Bark|Excellent. Jump onto my leafy head for a second spring. Find your design at the top, then we'll borrow the power cell and lens from home.","Mark|Borrow, return, and improve. In that order."],func():Mega.intro_done=true;Mega.save()))
func load_level(i):
	pickup_effects.clear();notice_until=0;hint_until=0;notice.hide();notice_back.hide();context_back.hide();last_shelf=maxi(0,int(Mega.runs[i].checkpoint)+1);ambient.color=Color(["fff7e5","f1f7ed","fff0d6"][i])
	Mega.current=i;Mega.save();mode="campus";close();campus.build(i);player.right_bound=1600;player.velocity=Vector2.ZERO;player.reset_jumps();spring_age=9;player.visual_scale=.24;player.sprite.scale=Vector2.ONE*.24;hud.show()
	var cp=int(Mega.runs[i].checkpoint)
	player.position=campus.platforms[cp].get_center()+Vector2(0,-12) if cp>=0 else Vector2(510,645)
	campus.bark.position=player.position+Vector2(-80,0);camera.position=Vector2(clampf(player.position.x,640,960),player.position.y-150)
	update_hud()
func level_select():
	var was_campus=mode=="campus"
	var return_to=close if was_campus else title
	var p=open(Rect2(105,115,1070,500));back=return_to
	text(p,"YOUR THREE GIANT CLIMBS",Rect2(30,24,1010,50),30)
	for i in range(3):
		var score=Mega.best[i]
		var c=card(p,Rect2(30+i*345,94,320,305),"efe2bc")
		var icon=TextureRect.new();icon.position=Vector2(108,18);icon.size=Vector2(104,80);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size=Vector2(104,80);icon.texture=Art.tex(campus.ASSETS[i]);c.add_child(icon)
		text(c,["THE LIBRARY LADDER","BEDROOM BEANSTALK","THE INVENTION ATTIC"][i],Rect2(15,110,290,42),20)
		text(c,["School · Gentle","Home · Adventurous","Home · Daring"][i]+"\n"+("Best: "+str(score.leaves)+" / 8 leaves · "+("Bark found" if score.token else "Secret hiding") if score.complete else "8 leaves + 1 secret to discover"),Rect2(15,157,290,75),17)
		var b=button(c,"Replay" if score.complete else "Continue" if i==Mega.current and Mega.intro_done else "Start climb",Rect2(15,242,290,48),func():choose(i),i==Mega.current)
		b.disabled=i>=Mega.unlocked
		if b.disabled:b.text="Locked · Finish level "+str(i)
	button(p,"Back",Rect2(380,428,310,55),return_to)
func choose(i):
	if Mega.best[i].complete:
		var p=open(Rect2(340,195,600,310));back=level_select
		text(p,"Replay this climb?",Rect2(30,25,540,45),29);text(p,"Your best score stays safe. This starts a fresh collection run for this level.",Rect2(30,91,540,90),22)
		button(p,"Back",Rect2(30,220,250,55),level_select,true);button(p,"Replay",Rect2(310,220,260,55),func():Mega.replay(i);load_level(i))
	else:load_level(i)
func say(lines,done=Callable()):
	dialogue=lines;page=0;dialogue_done=done
	var p=open(Rect2(120,380,1040,300));dialogue_label=text(p,"",Rect2(165,28,835,175),24)
	dialogue_portrait=TextureRect.new();var portrait=dialogue_portrait;portrait.position=Vector2(15,25);portrait.size=Vector2(135,180);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.size=Vector2(135,180);portrait.texture=Art.tex("bark_actions_hint");p.add_child(portrait)
	button(p,"Skip story",Rect2(175,222,240,55),end_dialogue);button(p,"Next / Finish [E]",Rect2(640,222,365,55),next_line,true);line()
func line():
	dialogue_portrait.texture=Art.tex("young_actions_notebook" if String(dialogue[page]).begins_with("Mark|") else "bark_actions_hint")
	dialogue_label.text=String(dialogue[page]).replace("|",":  ")+"\n\n"+str(page+1)+" / "+str(dialogue.size())
func next_line():
	page+=1
	if page>=dialogue.size():end_dialogue()
	else:line()
func end_dialogue():
	var done=dialogue_done;dialogue_done=Callable();close()
	if done.is_valid():done.call()
func jump():
	if not busy and mode=="campus":player.request_jump()
func jumped(second):
	play_sound("jump",1.15 if second else .95)
	if second:
		spring_age=0;spring_anchor=campus.bark.position;spring_facing=player.facing;spring_release_velocity=player.velocity.x;spring_contacts+=1
		campus.bark.texture=Art.tex("bark_actions_hop");player.spring_contact=true;player.show_pose("young_actions_crouch",.09)
		if spring_contacts%4==1:toast(["Bark: Feet on my leaves! Mark: Spring, please—not sneeze.","Bark: Try three jumps! Mark: We get two. Make this one count.","Bark: Aim for next Tuesday! Mark: The shelf will do."][int(spring_contacts/4)%3])
func landed(at,strength):
	if absf(at.y-650)<6:last_shelf=0
	for n in range(campus.RISES[Mega.current].size()):
		var r=campus.platforms[n]
		if absf(at.y-r.position.y)<6 and at.x>=r.position.x-15 and at.x<=r.end.x+15:last_shelf=n+1
	for n in range(campus.ledges.size()):
		var l=campus.ledges[n]
		if absf(at.y-l.position.y)<5 and at.x>=l.position.x-15 and at.x<=l.position.x+l.width+15:l.impact(strength)
	for n in range(campus.RISES[Mega.current].size()):
		var r=campus.platforms[n]
		if n%2==1 and n>int(Mega.runs[Mega.current].checkpoint) and absf(at.y-r.position.y)<5 and at.x>=r.position.x-10 and at.x<=r.end.x+10:
			Mega.runs[Mega.current].checkpoint=n;Mega.save();campus.refresh();toast("Checkpoint saved! Return here with R or the checkpoint button.")
func interact():
	if busy or mode!="campus":return
	var run=Mega.runs[Mega.current]
	if player.position.distance_to(campus.quest.pos)<125:
		if not player.is_on_floor():toast("Land on the shelf before picking up the quest item.");return
		if not run.quest:
			run.quest=true;Mega.save();campus.refresh();play_sound("collect")
			say([["Mark|My design! It needs a power cell and a focusing lens.","Bark|It also needs a flying sandwich. But we'll start with your list."],["Mark|The power cell. One more piece to go.","Bark|We could power it with my snoring!","Mark|Let's keep the neighbours asleep."],["Mark|The ray lens! Now we can fix our size—and return everything.","Bark|Set it to medium. Last time I selected 'unexpectedly enormous'."]][Mega.current])
		else:toast("Quest item secured. Reach the delivery point above.")
	elif player.position.distance_to(campus.exit)<125:
		if not player.is_on_floor():toast("Land at the delivery point, then use it.");return
		if not run.quest:toast("Recover the quest item on the shelf just below first.");return
		Mega.finish();play_sound("success");campus.bark.texture=Art.tex("bark_actions_cheer")
		if Mega.current==2:intro_ray.begin(func():load_level(2);result(),true)
		else:result()
	else:toast("Climb toward the next numbered shelf. E / Use picks up the quest item.")
func result():
	var i=Mega.current;var r=Mega.runs[i]
	var p=open(Rect2(270,100,740,540));back=close;result_open=true
	text(p,"CLIMB COMPLETE!" if i<2 else "SMALL FRIENDS. BIG IDEAS.",Rect2(30,25,680,55),32)
	text(p,["Design recovered. Next stop: Mark's bedroom!","Power cell collected. The last piece is in the attic!","The ray is repaired. Mark and Bark are full-sized again!\nMark: 'It worked!' Bark: 'My head deserves a holiday.'"][i],Rect2(30,105,680,100),23)
	text(p,"Leaves: "+str(r.leaves.size())+" / 8  ·  Bark token: "+("Found!" if r.token else "Still hiding")+"\nAward: "+("Curious explorer" if r.leaves.size()<6 else "Leaf champion")+(" + Secret finder" if r.token else ""),Rect2(30,230,680,80),22)
	var rosette=TextureRect.new();rosette.position=Vector2(305,315);rosette.size=Vector2(130,90);rosette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rosette.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;rosette.size=Vector2(130,90);rosette.texture=Art.tex("collectibles_science_rosette");p.add_child(rosette)
	button(p,"Next climb" if i<2 else "Explore this level",Rect2(30,420,330,65),func():next_level(i+1) if i<2 else close(),true)
	button(p,"Level select",Rect2(380,420,330,65),level_select)
func hint():
	if busy or mode!="campus":return
	var cp=int(Mega.runs[Mega.current].checkpoint)
	var next=mini(last_shelf,campus.RISES[Mega.current].size()-1)
	var in_secret=player.is_on_floor() and absf(player.position.y-campus.platforms[-1].position.y)<8
	if in_secret:next=4
	hint_target=campus.platforms[next].get_center();hint_until=clock+12;queue_redraw()
	var message="Follow the numbered shelves upward. Jump once, then jump again near the first apex: I will spring you higher. Each lit shelf is a checkpoint."
	if in_secret:message="Lovely side shelf! Return to shelf 5 on your right before climbing higher. Your secret token is safe."
	elif Mega.runs[Mega.current].quest:message="You have the quest item! Reach the delivery point on the top shelf and use it. Optional leaves can be collected later."
	elif player.position.y<campus.quest.pos.y+300:message="The quest item is on the shelf just below the delivery point. Land beside it, then press E / tap Use."
	say(["Bark|"+message,"Mark|And if we fall?","Bark|R, or the checkpoint button. Leaves and supplies stay with us!"])
func journal():
	if busy or mode!="campus":return
	var p=open(Rect2(265,155,750,455));var r=Mega.runs[Mega.current]
	text(p,"MARK'S CLIMBING NOTEBOOK",Rect2(30,25,690,45),28)
	text(p,campus.TITLES[Mega.current]+"\n\nQuest: "+campus.QUESTS[Mega.current]+(" · Secured" if r.quest else " · Find near the top")+"\nLeaves: "+str(r.leaves.size())+" / 8 · Bark token: "+("Found" if r.token else "Side shelf")+"\nCheckpoint: "+("Starting floor" if r.checkpoint<0 else "Shelf "+str(r.checkpoint+1))+"\n\nJump onto Bark for the second spring. Land to recharge.\nExplore lower shelves freely; R returns to the highest checkpoint.",Rect2(30,91,690,260),21)
	button(p,"Where next?",Rect2(30,370,290,60),func():close();hint());button(p,"Back",Rect2(370,370,350,60),close,true)
func next_level(i):
	if travelling:return
	if Progress.settings.reduced_motion:load_level(i);return
	travelling=true;busy=true;player.suspended=true;player.enabled=false;fingers.clear();travel_veil.modulate.a=0;travel_veil.show()
	var t=create_tween();t.tween_property(travel_veil,"modulate:a",1.0,.18);await t.finished
	load_level(i);busy=true;player.suspended=true;player.enabled=false
	t=create_tween();t.tween_property(travel_veil,"modulate:a",0.0,.24);await t.finished
	travel_veil.hide();travelling=false;busy=false;player.suspended=false;player.enabled=true
func how_to_play(return_to):
	var p=open(Rect2(245,120,790,500));back=return_to
	text(p,"TWO FRIENDS. TWO JUMPS.",Rect2(30,24,730,50),31)
	text(p,"1. Move with A/D, arrows or the touch arrows.\n2. Jump once, then again near the first apex.\n   Mark lands on Bark’s leaves for an extra spring.\n3. Land to recharge. Numbered shelves show the route.\n4. Land beside the quest item, then E / Use to collect.\n5. Deliver it at the summit to unlock the next climb.\n\nBulb shelves save checkpoints. R / Checkpoint brings\nyou back safely. Leaves and secrets stay collected.\nBark’s hint marks the next shelf. Hints are always free.",Rect2(30,100,730,290),22)
	button(p,"Got it",Rect2(225,420,340,55),return_to,true)
func retry():
	if mode!="campus" or (busy and is_instance_valid(dialogue_label)):return
	close();var cp=int(Mega.runs[Mega.current].checkpoint);last_shelf=maxi(0,cp+1)
	player.position=campus.platforms[cp].get_center()+Vector2(0,-12) if cp>=0 else Vector2(510,645)
	player.velocity=Vector2.ZERO;player.reset_jumps();spring_age=9;campus.bark.rotation=0;campus.bark.scale=Vector2(.2*player.facing,.2);campus.bark.position=player.position+Vector2(-80,0);camera.position=Vector2(clampf(player.position.x,640,960),player.position.y-150)
	toast("Back at your checkpoint. Every discovery is safe.")
func pause_game():
	if mode!="campus" or busy:return
	var p=open(Rect2(390,145,500,460))
	text(p,"A LITTLE BREATHER",Rect2(30,25,440,45),29)
	button(p,"Continue",Rect2(30,95,440,60),close,true);button(p,"Return to checkpoint",Rect2(30,173,440,60),retry);button(p,"Settings",Rect2(30,251,440,60),func():settings(func():close();pause_game()));button(p,"Save & title",Rect2(30,329,440,60),func():Mega.save();title())
func settings(return_to):
	var p=open(Rect2(285,130,710,460));back=return_to
	text(p,"SETTINGS & CONTROLS",Rect2(30,25,650,45),30)
	var percent=text(p,str(roundi(Progress.settings.volume*100))+"%",Rect2(570,99,95,35),22)
	text(p,"Sound",Rect2(30,99,150,35),22)
	var slider=HSlider.new();slider.position=Vector2(180,100);slider.size=Vector2(365,35);slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=Progress.settings.volume;p.add_child(slider);slider.value_changed.connect(func(v):Progress.settings.volume=v;percent.text=str(roundi(v*100))+"%";Progress.save_game());slider.grab_focus()
	for n in range(3):
		var key=["reduced_motion","music","touch"][n]
		var t=CheckButton.new();t.text=["Reduced motion","Background music","Always show touch controls"][n];t.position=Vector2(30,158+n*54);t.size=Vector2(650,46);t.button_pressed=Progress.settings[key];t.add_theme_font_override("font",Art.font);t.add_theme_font_size_override("font_size",22)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:t.add_theme_color_override(state,Color("203849"))
		t.add_theme_icon_override("checked",load("res://assets/ui_toggle_on.svg"));t.add_theme_icon_override("unchecked",load("res://assets/ui_toggle_off.svg"));p.add_child(t);t.toggled.connect(func(v):Progress.settings[key]=v;Progress.save_game())
	text(p,"Space twice: jump + Bark spring · E: use · R: checkpoint\nTouch: hold arrows and tap Jump twice. Play in landscape.",Rect2(30,320,650,55),17)
	button(p,"Back",Rect2(210,390,290,55),return_to,true)
func play_sound(id,pitch=1.0):
	if sound_bank.has(id) and Progress.settings.volume>0:
		effects.stream=sound_bank[id];effects.pitch_scale=pitch;effects.volume_db=linear_to_db(Progress.settings.volume*.6);effects.play()
func toast(value):
	notice.text=value;notice_until=clock+maxf(5,float(String(value).length())/18.0);notice_back.size.y=74 if String(value).length()<95 else 96;notice.size.y=notice_back.size.y-16
func update_hud():
	var r=Mega.runs[Mega.current]
	objective_icon.texture=Art.tex("ui_parts_reward_check" if r.quest else campus.ASSETS[Mega.current])
	height_meter.value=clampf((650-player.position.y)/(650-campus.top)*100,0,100)
	route_label.text="Shelf "+str(last_shelf)+" / "+str(campus.RISES[Mega.current].size())+"\nClimb "+str(roundi(height_meter.value))+"%"
	objective.text=str(Mega.current+1)+" / 3 · "+campus.TITLES[Mega.current]+"\n"+("Deliver: "+campus.QUESTS[Mega.current]+" at the top." if r.quest else "Recover: "+campus.QUESTS[Mega.current]+".")
	counters.text="Leaves "+str(r.leaves.size())+" / 8\nBark "+("Found" if r.token else "Hidden")+"\n"+("2 jumps ready" if player.is_on_floor() else "Bark spring" if player.jumps_used<2 else "Land to reset")
	var at_exit=player.position.distance_to(campus.exit)<125
	var near=player.position.distance_to(campus.quest.pos)<125 or at_exit
	context.text=("Use" if touch_mode else "[E]")+": "+("deliver quest item" if at_exit else "quest item secured" if r.quest else "pick up quest item") if near else ""
	if Mega.current==0 and Mega.runs[0].checkpoint<1 and not near:context.text="Jump, then jump again to spring off Bark. Land to recharge."
	touch_root.visible=touch_mode or Progress.settings.touch or OS.has_feature("mobile")
	for c in hud.get_children():
		if c is Button and c.position.x==20:c.visible=not touch_root.visible
		if c is Button and c.position.x==270:c.text="Bark's hint" if touch_root.visible else "Bark's hint [H]"
		if c is Button and c.name=="TouchNotebook":c.visible=touch_root.visible
		if c is Button and c.position.x==540 and c.name!="TouchNotebook":c.text="Checkpoint" if touch_root.visible else "Checkpoint [R]"
func _physics_process(delta):
	clock+=delta;queue_redraw()
	if not busy:
		for sparkle in pickup_effects:sparkle.age+=delta
		pickup_effects=pickup_effects.filter(func(p):return p.age<.6)
	if is_instance_valid(effects):effects.volume_db=linear_to_db(maxf(.0001,Progress.settings.volume*.6))
	if mode!="campus":return
	player.reduced_motion=Progress.settings.reduced_motion;campus.reduced_motion=player.reduced_motion
	player.axis=0 if busy else clampf(Input.get_axis("left","right")+float("right" in fingers.values())-float("left" in fingers.values()),-1,1)
	if busy:
		notice_until+=delta;hint_until+=delta;notice.hide();notice_back.hide();context.hide();context_back.hide();return
	context.show();player.spring_contact=spring_age<.22
	var target=Vector2(clampf(player.position.x+player.velocity.x*.1,640,960),clampf(player.position.y-105,campus.top-400,450))
	camera.position=target if player.reduced_motion else camera.position.lerp(target,1-exp(-delta*9))
	var r=Mega.runs[Mega.current]
	for p in campus.pickups:
		if p.sprite.visible and player.position.distance_to(p.pos+Vector2(0,35))<80:
			if p.kind=="leaf":r.leaves.append(p.id);toast("Leaf found! "+str(r.leaves.size())+" / 8. Optional discoveries never block your climb.")
			else:r.token=true;toast("Bark: My secret portrait! Mark: Your grin gave it away.")
			Mega.save();campus.refresh();play_sound("collect",1.2)
			if not player.reduced_motion:pickup_effects.append({"at":p.pos+Vector2(0,-22),"age":0.0})
	if player.position.y>950:retry()
	notice.visible=clock<notice_until;notice.position.y=438 if player.get_global_transform_with_canvas().origin.y<380 else 150
	notice_back.visible=notice.visible;notice_back.position.y=notice.position.y-9
	context_back.visible=not context.text.is_empty()
	update_hud()
# Runs after Mark's move_and_slide: Bark never trails a physics tick behind.
# Visual anticipation and recovery do not delay or alter the jump impulse.
func update_bark_jump(delta: float) -> void:
	if mode!="campus" or busy:return
	var bark=campus.bark
	# Landings interrupt the airborne choreography, including low ceiling hops.
	if player.is_on_floor() and spring_age<.45:
		spring_age=9.0
		player.spring_contact=false
	var age_before=spring_age
	spring_age+=delta
	var goal: Vector2
	var desired_scale=Vector2(.2*player.facing,.2)
	var response=9.0
	if spring_age<.10:
		# Bark is already moving beneath Mark during the first jump. Any
		# remaining gap closes smoothly, including immediate rescue springs.
		goal=player.position+Vector2(0,54)+player.velocity/32.0
		response=32.0
		desired_scale=Vector2(.21*spring_facing,.18)
		spring_anchor=bark.position
	elif spring_age<.45:
		if age_before<.10:
			spring_anchor=bark.position
			player.show_pose("young_actions_jump",.23)
		var release=clampf((spring_age-.10)/.35,0,1)
		# Depart from the actual contact position, without a phase-boundary snap.
		goal=spring_anchor+Vector2(spring_release_velocity*.10*release,28*release*release)
		response=18.0
		desired_scale=Vector2(.19*spring_facing,.22)
	else:
		var ready=not player.is_on_floor() and player.jumps_used<2
		goal=player.position+Vector2(0,60)+player.velocity/22.0 if ready else player.position+Vector2(-75*player.facing,0)
		if player.is_on_floor():
			# Keep a resting companion on the same shelf even near its edge.
			for shelf in campus.platforms:
				if absf(player.position.y-shelf.position.y)<6 and player.position.x>=shelf.position.x-15 and player.position.x<=shelf.end.x+15:
					goal.x=clampf(goal.x,shelf.position.x+16,shelf.end.x-16)
					break
			goal.y=campus.support_y(goal.x,player.position.y)
		response=22.0 if ready else 9.0
		bark.texture=Art.tex("bark_actions_hop" if ready else ("bark_actions_walk_stride_a" if absf(player.velocity.x)>30 else "bark_actions_idle"))
	bark.position=bark.position.lerp(goal,1-exp(-delta*response))
	if player.reduced_motion:
		bark.scale=Vector2.ONE*.2 if spring_age<.45 else Vector2(.2*player.facing,.2)
		bark.rotation=0
	else:
		# Keep facing fixed through contact; ease squash, release and settling.
		if signf(bark.scale.x)!=signf(desired_scale.x):bark.scale.x=-bark.scale.x
		bark.scale=bark.scale.lerp(desired_scale,1-exp(-delta*20))
		var lean=clampf(player.velocity.x/10000.0,-.026,.026) if spring_age<.45 else 0.0
		bark.rotation=lerpf(bark.rotation,lean,1-exp(-delta*15))

func _input(e):
	if e is InputEventScreenTouch:
		touch_mode=true
		if not e.pressed:fingers.erase(e.index)
		elif not busy and mode=="campus":
			if Rect2(20,620,90,70).has_point(e.position):fingers[e.index]="left";get_viewport().set_input_as_handled()
			elif Rect2(120,620,90,70).has_point(e.position):fingers[e.index]="right";get_viewport().set_input_as_handled()
			elif Rect2(830,620,180,70).has_point(e.position):jump();get_viewport().set_input_as_handled()
			elif Rect2(1030,620,220,70).has_point(e.position):interact();get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag and fingers.has(e.index):
		var rect=Rect2(20,620,90,70) if fingers[e.index]=="left" else Rect2(120,620,90,70)
		if not rect.grow(20).has_point(e.position):fingers.erase(e.index)
	elif e is InputEventKey and e.pressed:touch_mode=false
func _unhandled_input(e):
	if travelling:return
	if e is InputEventKey and e.echo:return
	if e.is_action_pressed("pause"):
		if busy:
			if mode=="ray":intro_ray.finish()
			elif is_instance_valid(dialogue_label):end_dialogue()
			elif back.is_valid():back.call()
			elif mode=="campus":close()
		else:pause_game()
	elif e.is_action_pressed("interact"):
		if mode=="ray":intro_ray.finish()
		elif busy and is_instance_valid(dialogue_label):next_line()
		elif not busy:interact()
	elif e.is_action_pressed("jump"):jump()
	elif e.is_action_pressed("hint"):hint()
	elif e.is_action_pressed("notebook"):journal()
	elif e.is_action_pressed("retry") and not busy:retry()
func _notification(what):
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(player):
		Input.action_release("left");Input.action_release("right");fingers.clear();player.axis=0
		if mode=="campus" and not busy:pause_game()
	if what==NOTIFICATION_WM_CLOSE_REQUEST and not quitting:
		quitting=true;Mega.save();Progress.save_game();effects.stop();effects.stream=null;await soundscape.drain();get_tree().quit()

func _draw():
	if mode=="campus" and not busy and not Progress.settings.reduced_motion:
		for sparkle in pickup_effects:
			var ratio=sparkle.age/.6
			for n in range(6):
				var at=sparkle.at+Vector2(cos(n*TAU/6),sin(n*TAU/6))*(12+ratio*34)+Vector2(0,-ratio*25)
				draw_colored_polygon(PackedVector2Array([at+Vector2(-3,0),at+Vector2(0,-5),at+Vector2(3,0),at+Vector2(0,5)]),Color(1,.88,.49,(1-ratio)*.8))
	if mode=="campus" and not busy:
		var target=campus.exit if Mega.runs[Mega.current].quest else campus.quest.pos
		if player.position.distance_to(target)<145:
			for side in [-1,1]:
				draw_polyline(PackedVector2Array([target+Vector2(side*48,-20),target+Vector2(side*58,-20),target+Vector2(side*58,-90),target+Vector2(side*48,-90)]),Color("ffe3a1"),3)
	if mode=="campus" and not busy and clock<hint_until:
		var p=hint_target+Vector2(0,-75)
		draw_arc(p,32,0,TAU,32,Color("f4df9a"),3)
		draw_line(p+Vector2(0,-15),p+Vector2(0,13),Color("203849"),4)
		draw_polyline(PackedVector2Array([p+Vector2(-10,3),p+Vector2(0,13),p+Vector2(10,3)]),Color("203849"),4)
