extends Node2D
const TITLES=["SCHOOL · THE LIBRARY LADDER","HOME · THE BEDROOM BEANSTALK","HOME · THE INVENTION ATTIC"]
const QUESTS=["Mark's missing design","The pocket-sized power cell","The golden ray lens"]
const ASSETS=["collectibles_notebook","mega_power_cell","mega_ray_lens"]
const RISES=[[140,180,190,195,180,210,190,185],[145,195,205,210,220,200,220,205,200],[150,205,215,230,225,220,230,225,220,225,215]]
const CENTERS=[[720,985,750,495,760,1025,770,510],[710,980,720,455,725,1000,740,470,745],[710,960,690,445,710,975,725,470,740,990,735]]
var level=0
var room=0
var tutorial=false
var platforms: Array[Rect2]=[]
var ledges: Array=[]
var pickups: Array=[]
var quest: Dictionary
var exit: Vector2
var bark: Sprite2D
var top=0.0
var clock=0.0
var reduced_motion=false
var scenery
var checkpoints=[]
func build(i):
	for c in get_children():remove_child(c);c.queue_free()
	level=i;room=0;platforms=[];ledges=[];pickups=[];checkpoints=[]
	scenery=load("res://scripts/mega_scenery.gd").new();scenery.level=i;scenery.z_index=-10;add_child(scenery)
	body(Rect2(0,650,1600,100),false)
	var y=650.0
	for n in range(RISES[i].size()):
		y-=RISES[i][n]
		var w=280-i*36
		var r=Rect2(CENTERS[i][n]-w/2,y,w,22)
		platforms.append(r);body(r,true)
		var l=load("res://scripts/fun_platform.gd").new();l.position=r.position;l.width=w;l.kind="book" if i==0 else "pencil" if n%3==1 else "book";l.z_index=1;add_child(l);ledges.append(l)
		if n%2==1:
			var icon=Art.prop("ui_parts_hint_bulb",35);icon.position=Vector2(r.position.x+30,y);add_child(icon);checkpoints.append({"index":n,"sprite":icon})
		label(str(n+1),Vector2(r.end.x-35,y+10),15)
		if n<8:
			pickup("leaf",n,"collectibles_leaf_token",Vector2(CENTERS[i][n]+65,y-22),52)
	top=y
	# A reachable optional side shelf, never required for the exit.
	var r=platforms[4];var side_x=r.get_center().x-245
	var secret=Rect2(side_x-85,r.position.y-70,170,22);body(secret,true);platforms.append(secret)
	var l=load("res://scripts/fun_platform.gd").new();l.position=secret.position;l.width=170;l.kind="leaf";l.z_index=1;add_child(l);ledges.append(l)
	prop("school_props_plant",Vector2(side_x-55,secret.position.y),105)
	pickup("token",0,"collectibles_bark_token",Vector2(side_x+25,secret.position.y),70)
	label("SECRET NOOK",Vector2(side_x-65,secret.position.y+46),14)
	var q=platforms[RISES[i].size()-2]
	quest={"pos":Vector2(q.get_center().x,q.position.y),"sprite":prop(ASSETS[i],Vector2(q.get_center().x,q.position.y),90)}
	exit=Vector2(CENTERS[i][-1],top)
	prop("school_props_noticeboard" if i==0 else "school_props_desk",exit,165)
	label("DELIVERY POINT",exit+Vector2(-100,-170),18)
	bark=Art.character("bark_actions_idle");bark.scale=Vector2.ONE*.20;bark.position=Vector2(410,650);bark.z_index=4;add_child(bark)
	refresh()
func body(r: Rect2, one_way: bool):
	var b=StaticBody2D.new();b.collision_layer=1;b.collision_mask=2
	var c=CollisionShape2D.new();var s=RectangleShape2D.new();s.size=r.size;c.shape=s;c.position=r.get_center();c.one_way_collision=one_way;c.one_way_collision_margin=10;b.add_child(c);add_child(b)
func prop(id,pos,size):
	var s=Art.prop(id,size);s.position=pos;s.z_index=2;add_child(s);return s
func pickup(kind,id,asset,pos,size):
	pickups.append({"kind":kind,"id":id,"pos":pos,"sprite":prop(asset,pos,size)})
func label(text,pos,size):
	var l=Label.new();l.text=text;l.position=pos;l.size=Vector2(220,45);l.add_theme_font_override("font",Art.font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("fff2ce"));l.add_theme_color_override("font_shadow_color",Color("203849"));l.add_theme_constant_override("shadow_offset_y",2);l.z_index=2;add_child(l)
func support_y(x,y):
	var result=650.0
	for p in platforms:
		if x>=p.position.x-6 and x<=p.end.x+6 and p.position.y>=y-8:result=minf(result,p.position.y)
	return result
func refresh():
	var r=Mega.runs[level]
	for p in pickups:p.sprite.visible=not (p.id in r.leaves if p.kind=="leaf" else r.token)
	if not quest.is_empty():quest.sprite.visible=not r.quest
	for c in checkpoints:
		c.sprite.texture=Art.tex("ui_parts_reward_check" if c.index<=r.checkpoint else "ui_parts_hint_bulb")
	if is_instance_valid(scenery):scenery.queue_redraw()
func _process(delta):
	clock+=delta
	for l in ledges:l.reduced_motion=reduced_motion
	for p in pickups:
		p.sprite.position=p.pos if reduced_motion else p.pos+Vector2(0,sin(clock*2+p.id)*2)
	scenery.reduced_motion=reduced_motion
