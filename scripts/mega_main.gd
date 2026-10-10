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
var dialogue=[]
var page=0
var dialogue_portrait: TextureRect
var dialogue_label: Label
var dialogue_done: Callable
var back: Callable
var clock=0.0
var notice_until=0.0
var quitting=false
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
	player=load("res://scripts/player.gd").new();add_child(player);player.right_bound=1600;player.position=Vector2(510,645);player.jumped.connect(jumped);player.landed.connect(landed)
	camera=Camera2D.new();camera.position=Vector2(800,330);add_child(camera);camera.make_current()
	var canvas=CanvasLayer.new();canvas.layer=10;add_child(canvas)
	hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(hud)
	var head=card(hud,Rect2(20,16,1240,112),"203849")
	objective=text(head,"",Rect2(22,13,865,82),23,"fff3d3")
	counters=text(head,"",Rect2(920,15,165,85),17,"fff3d3")
	button(head,"Pause",Rect2(1098,27,120,55),pause_game)
	context=text(hud,"",Rect2(260,575,760,40),20,"fff3d3");context.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;context.add_theme_color_override("font_shadow_color",Color("203849"));context.add_theme_constant_override("shadow_offset_y",2)
	notice=text(hud,"",Rect2(285,146,710,65),20,"fff3d3");notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.add_theme_color_override("font_shadow_color",Color("203849"));notice.add_theme_constant_override("shadow_offset_y",2)
	button(hud,"Notebook [N]",Rect2(20,620,230,70),journal)
	button(hud,"Notes",Rect2(1110,140,140,50),journal).name="TouchNotebook"
	button(hud,"Bark's hint [H]",Rect2(270,620,250,70),hint)
	button(hud,"Checkpoint [R]",Rect2(540,620,250,70),retry)
	touch_root=Control.new();touch_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(touch_root)
	button(touch_root,"◀",Rect2(20,620,90,70),func():pass)
	button(touch_root,"▶",Rect2(120,620,90,70),func():pass)
	button(touch_root,"Jump",Rect2(830,620,180,70),jump)
	button(touch_root,"Use",Rect2(1030,620,220,70),interact)
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(overlay)
	veil=ColorRect.new();veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);veil.color=Color(.07,.12,.15,.48);veil.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(veil);veil.hide()
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
	b.add_theme_stylebox_override("normal",style("203849" if primary else "fff3d3"));b.add_theme_stylebox_override("hover",style("436575" if primary else "e6d49f"));b.add_theme_stylebox_override("pressed",style("263e4b" if primary else "d7bc78"))
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("e7bf63");focus.set_border_width_all(4);focus.set_corner_radius_all(18);b.add_theme_stylebox_override("focus",focus)
	b.focus_mode=Control.FOCUS_NONE if parent==hud or parent==touch_root or parent.get_parent()==hud else Control.FOCUS_ALL
	parent.add_child(b);b.pressed.connect(action)
	if primary:b.grab_focus()
	return b
func close():
	if is_instance_valid(panel):panel.queue_free();overlay.remove_child(panel)
	panel=null;veil.hide();busy=false;player.suspended=false;player.enabled=mode=="campus";fingers.clear();dialogue_label=null;back=Callable()
func open(r):
	close();busy=true;player.suspended=true;player.enabled=false;player.axis=0;veil.show();panel=card(overlay,r);return panel
func title():
	mode="title";hud.hide();campus.build(0);player.position=Vector2(1130,645);player.velocity=Vector2.ZERO;camera.position=Vector2(800,330);campus.bark.position=Vector2(1290,650)
	var p=open(Rect2(55,60,710,600))
	text(p,"MARK & BARK",Rect2(35,25,640,65),42);text(p,"THE TINY, TALL ADVENTURE",Rect2(35,97,640,40),26,"8a713f")
	text(p,"A shrinking ray. Three giant climbs.\nOne inventor and one spectacularly unhelpful tree.",Rect2(35,153,640,80),22)
	button(p,"Continue climb" if Mega.intro_done else "Start the adventure",Rect2(35,252,640,65),start,true)
	button(p,"Choose a level",Rect2(35,337,310,60),level_select)
	button(p,"Settings",Rect2(365,337,310,60),func():settings(title))
	button(p,"New adventure",Rect2(35,417,640,60),confirm_new)
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
	Mega.current=i;Mega.save();mode="campus";close();campus.build(i);player.right_bound=1600;player.velocity=Vector2.ZERO;player.reset_jumps();spring_age=9;hud.show()
	var cp=int(Mega.runs[i].checkpoint)
	player.position=campus.platforms[cp].get_center()+Vector2(0,-12) if cp>=0 else Vector2(510,645)
	campus.bark.position=player.position+Vector2(-80,0);camera.position=Vector2(clampf(player.position.x,640,960),player.position.y-150)
	update_hud()
func level_select():
	var p=open(Rect2(245,145,790,460));back=title
	text(p,"THREE GIANT CLIMBS",Rect2(30,25,730,50),30)
	for i in range(3):
		var unlocked=i<Mega.unlocked
		var score=Mega.best[i]
		var b=button(p,str(i+1)+". "+["School library · Gentle","Bedroom shelves · Adventurous","Invention attic · Daring"][i]+(" · "+str(score.leaves)+"/8" if score.complete else ""),Rect2(30,100+i*86,730,65),func():choose(i),unlocked and i==Mega.current)
		b.disabled=not unlocked
		if not unlocked:b.text+=" · Locked"
	button(p,"Back",Rect2(255,370,280,60),title)
func choose(i):
	if Mega.best[i].complete:
		var p=open(Rect2(340,195,600,310));back=level_select
		text(p,"Replay this climb?",Rect2(30,25,540,45),29);text(p,"Your best score stays safe. This starts a fresh collection run for this level.",Rect2(30,91,540,90),22)
		button(p,"Back",Rect2(30,220,250,55),level_select,true);button(p,"Replay",Rect2(310,220,260,55),func():Mega.replay(i);load_level(i))
	else:load_level(i)
func say(lines,done=Callable()):
	dialogue=lines;page=0;dialogue_done=done
	var p=open(Rect2(120,380,1040,300));dialogue_label=text(p,"",Rect2(165,28,835,175),24)
	dialogue_portrait=TextureRect.new();var portrait=dialogue_portrait;portrait.texture=Art.tex("bark_actions_hint");portrait.position=Vector2(15,25);portrait.size=Vector2(135,180);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;p.add_child(portrait)
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
		spring_age=0;spring_anchor=player.position;spring_contacts+=1
		campus.bark.position=player.position+Vector2(0,54);campus.bark.texture=Art.tex("bark_actions_hop");player.show_pose("young_actions_crouch",.09)
		if spring_contacts%4==1:toast(["Bark: Feet on my leaves! Mark: Spring, please—not sneeze.","Bark: Try three jumps! Mark: We get two. Make this one count.","Bark: Aim for next Tuesday! Mark: The shelf will do."][int(spring_contacts/4)%3])
func landed(at,strength):
	for n in range(campus.ledges.size()):
		var l=campus.ledges[n]
		if absf(at.y-l.position.y)<5 and at.x>=l.position.x-15 and at.x<=l.position.x+l.width+15:l.impact(strength)
	for n in range(campus.RISES[Mega.current].size()):
		var r=campus.platforms[n]
		if n%2==1 and n>int(Mega.runs[Mega.current].checkpoint) and absf(at.y-r.position.y)<5 and at.x>=r.position.x-10 and at.x<=r.end.x+10:
			Mega.runs[Mega.current].checkpoint=n;Mega.save();toast("Checkpoint saved! Return here with R or the checkpoint button.")
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
	var p=open(Rect2(270,145,740,470));back=title
	text(p,"CLIMB COMPLETE!" if i<2 else "SMALL FRIENDS. BIG IDEAS.",Rect2(30,25,680,55),32)
	text(p,["Design recovered. Next stop: Mark's bedroom!","Power cell collected. The last piece is in the attic!","The ray is repaired. Mark and Bark are full-sized again!\nMark: 'It worked!' Bark: 'My head deserves a holiday.'"][i],Rect2(30,105,680,100),23)
	text(p,"Leaves: "+str(r.leaves.size())+" / 8  ·  Bark token: "+("Found!" if r.token else "Still hiding")+"\nAward: "+("Curious explorer" if r.leaves.size()<6 else "Leaf champion")+(" + Secret finder" if r.token else ""),Rect2(30,230,680,80),22)
	button(p,"Next climb" if i<2 else "Explore this level",Rect2(30,355,330,65),func():load_level(i+1) if i<2 else close(),true)
	button(p,"Level select",Rect2(380,355,330,65),level_select)
func hint():
	if busy or mode!="campus":return
	var cp=int(Mega.runs[Mega.current].checkpoint)
	var next=0
	for n in range(campus.RISES[Mega.current].size()):
		if campus.platforms[n].position.y<player.position.y-15:next=n;break
	hint_target=campus.platforms[next].get_center();hint_until=clock+12;queue_redraw()
	var message="Follow the numbered shelves upward. Jump once, then jump again near the first apex: I will spring you higher. Each lit shelf is a checkpoint."
	if Mega.runs[Mega.current].quest:message="You have the quest item! Reach the delivery point on the top shelf and use it. Optional leaves can be collected later."
	elif player.position.y<campus.quest.pos.y+300:message="The quest item is on the shelf just below the delivery point. Land beside it, then press E / tap Use."
	say(["Bark|"+message,"Mark|And if we fall?","Bark|R, or the checkpoint button. Leaves and supplies stay with us!"])
func journal():
	if busy or mode!="campus":return
	var p=open(Rect2(265,155,750,455));var r=Mega.runs[Mega.current]
	text(p,"MARK'S CLIMBING NOTEBOOK",Rect2(30,25,690,45),28)
	text(p,campus.TITLES[Mega.current]+"\n\nQuest: "+campus.QUESTS[Mega.current]+(" · Secured" if r.quest else " · Find near the top")+"\nLeaves: "+str(r.leaves.size())+" / 8 · Bark token: "+("Found" if r.token else "Side shelf")+"\nCheckpoint: "+("Starting floor" if r.checkpoint<0 else "Shelf "+str(r.checkpoint+1))+"\n\nJump onto Bark for the second spring. Land to recharge.\nExplore lower shelves freely; R returns to the highest checkpoint.",Rect2(30,91,690,260),21)
	button(p,"Where next?",Rect2(30,370,290,60),func():close();hint());button(p,"Back",Rect2(370,370,350,60),close,true)
func retry():
	if mode!="campus" or (busy and is_instance_valid(dialogue_label)):return
	close();var cp=int(Mega.runs[Mega.current].checkpoint)
	player.position=campus.platforms[cp].get_center()+Vector2(0,-12) if cp>=0 else Vector2(510,645)
	player.velocity=Vector2.ZERO;player.reset_jumps();spring_age=9;campus.bark.position=player.position+Vector2(-80,0);camera.position=Vector2(clampf(player.position.x,640,960),player.position.y-150)
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
	notice.text=value;notice_until=clock+6
func update_hud():
	var r=Mega.runs[Mega.current]
	objective.text=str(Mega.current+1)+" / 3 · "+campus.TITLES[Mega.current]+"\n"+("Deliver: "+campus.QUESTS[Mega.current]+" at the top." if r.quest else "Climb to recover "+campus.QUESTS[Mega.current]+".")
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
	if mode!="campus":return
	player.reduced_motion=Progress.settings.reduced_motion;campus.reduced_motion=player.reduced_motion
	player.axis=0 if busy else clampf(Input.get_axis("left","right")+float("right" in fingers.values())-float("left" in fingers.values()),-1,1)
	if busy:
		notice_until+=delta;hint_until+=delta;notice.hide();context.hide();return
	context.show()
	var target=Vector2(clampf(player.position.x+player.velocity.x*.1,640,960),clampf(player.position.y-105,campus.top-400,450))
	camera.position=target if player.reduced_motion else camera.position.lerp(target,1-exp(-delta*9))
	spring_age+=delta
	if spring_age<.10:
		campus.bark.position=player.position+Vector2(0,54);campus.bark.scale=Vector2(.21,.18) if not player.reduced_motion else Vector2.ONE*.2
	elif spring_age<.45:
		if spring_age<.13:player.show_pose("young_actions_jump",.3)
		campus.bark.position=spring_anchor+Vector2(0,66-(sin((spring_age-.1)/.35*PI)*18 if not player.reduced_motion else 0));campus.bark.scale=Vector2(.19,.22) if not player.reduced_motion else Vector2.ONE*.2
	else:
		var goal=player.position+Vector2(-75*player.facing,0);goal.y=campus.support_y(goal.x,player.position.y) if player.is_on_floor() else player.position.y
		campus.bark.position=campus.bark.position.lerp(goal,1-exp(-delta*8));campus.bark.scale=Vector2(.2*player.facing,.2);campus.bark.texture=Art.tex("bark_actions_walk_stride_a" if absf(player.velocity.x)>30 else "bark_actions_idle")
	var r=Mega.runs[Mega.current]
	for p in campus.pickups:
		if p.sprite.visible and player.position.distance_to(p.pos+Vector2(0,35))<80:
			if p.kind=="leaf":r.leaves.append(p.id);toast("Leaf found! "+str(r.leaves.size())+" / 8. Optional discoveries never block your climb.")
			else:r.token=true;toast("Bark: My secret portrait! Mark: Your grin gave it away.")
			Mega.save();campus.refresh();play_sound("collect",1.2)
	if player.position.y>950:retry()
	notice.visible=clock<notice_until;notice.position.y=440 if player.get_global_transform_with_canvas().origin.y<380 else 146
	update_hud()
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
	if mode=="campus" and not busy and clock<hint_until:
		var p=hint_target+Vector2(0,-75)
		draw_arc(p,32,0,TAU,32,Color("f4df9a"),3)
		draw_line(p+Vector2(0,-15),p+Vector2(0,13),Color("203849"),4)
		draw_polyline(PackedVector2Array([p+Vector2(-10,3),p+Vector2(0,13),p+Vector2(10,3)]),Color("203849"),4)
