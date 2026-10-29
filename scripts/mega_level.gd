extends Node2D
const TITLES=["SCHOOL · THE LIBRARY LADDER","HOME · THE BEDROOM BEANSTALK","HOME · THE INVENTION ATTIC"]
const QUESTS=["Mark's missing design","The pocket-sized power cell","The golden ray lens"]
const ASSETS=["collectibles_notebook","mega_power_cell","mega_ray_lens"]
const BASE_RISES=[[140,180,190,195,180,210,190,185],[145,195,205,210,220,200,220,205,200],[150,205,215,230,225,220,230,225,220,225,215]]
const BASE_CENTERS=[[720,985,750,495,760,1025,770,510],[710,980,720,455,725,1000,740,470,745],[710,960,690,445,710,975,725,470,740,990,735]]
const RISES=[BASE_RISES[0]+BASE_RISES[0]+BASE_RISES[0],BASE_RISES[1]+BASE_RISES[1]+BASE_RISES[1],BASE_RISES[2]+BASE_RISES[2]+BASE_RISES[2]]
const DISTRICTS=[["Reading nook","Pencil crossing","The roof library"],["Toy corner","Wardrobe trail","Window garden"],["Workshop floor","Thread loft","Ray observatory"]]
const KINDS=["book","eraser","spool","pencil","ruler","plank"]
const LEAF_COUNT=24
var level=0
var room=0
var tutorial=false
var platforms: Array[Rect2]=[]
var ledges: Array=[]
var pickups: Array=[]
var quest: Dictionary={}
var exit: Vector2
var bark: Sprite2D
var top=0.0
var clock=0.0
var reduced_motion=false
var scenery
var whimsy
var checkpoints=[]
var branches=[]
var branch_indices=[]
var leaf_shelves=[]
var enemies=[]
var enemy_grace=1.8
var last_safe=Vector2(510,647)
var safe_shelf=0
func build(i):
	for c in get_children():remove_child(c);c.queue_free()
	level=i;room=0;platforms=[];ledges=[];pickups=[];checkpoints=[];branches=[];branch_indices=[];leaf_shelves=[];enemies=[];quest={};enemy_grace=1.8;last_safe=Vector2(510,647);safe_shelf=0
	var height=0.0
	for rise in RISES[i]:height+=rise
	top=650-height
	scenery=load("res://scripts/mega_scenery.gd").new();scenery.level=i;scenery.top=top-900;scenery.z_index=-10;add_child(scenery)
	whimsy=load("res://scripts/whimsy_layer.gd").new();whimsy.name="WhimsyLayer";whimsy.context="climb";whimsy.level=i;whimsy.top=top-900;whimsy.controller=get_parent();whimsy.z_index=-3;add_child(whimsy)
	body(Rect2(0,650,1600,150),false)
	# Twenty-four evenly spread discoveries, including the upper attic.
	for id in range(LEAF_COUNT):leaf_shelves.append(roundi(float(id)*(RISES[i].size()-1)/(LEAF_COUNT-1)))
	for id in [4,12,20]:branch_indices.append(leaf_shelves[id])
	var y=650.0
	for n in range(RISES[i].size()):
		y-=RISES[i][n]
		var x=route_x(i,n)
		var width=360.0 if n%6==3 else float(280-i*30)
		if n%BASE_RISES[i].size()==0:width=320
		var r=Rect2(x-width/2,y,width,22);platforms.append(r);body(r,true)
		var ledge=painted_ledge(r,KINDS[(n+i*2)%KINDS.size()]);ledges.append(ledge)
		if n%2==1:
			var icon=prop("ui_parts_hint_bulb",Vector2(r.position.x+28,y),35);checkpoints.append({"index":n,"sprite":icon})
		label(str(n+1),Vector2(r.end.x-35,y+8),15)
		var leaf_id=leaf_shelves.find(n)
		if leaf_id>=0 and not leaf_id in [4,12,20]:pickup("leaf",leaf_id,"collectibles_leaf_token",Vector2(x+58,y-22),48)
		if n%6==4:
			var enemy=load("res://scripts/variety_enemy.gd").new();var far_side=1 if route_x(i,n-1)<x else -1;enemy.home=Vector2(x+76*far_side,y-20);enemy.position=enemy.home;enemy.kind=(int(n/6)+i)%3;enemy.seed_phase=n*.7;enemy.z_index=3;add_child(enemy);enemies.append(enemy)
		if n%BASE_RISES[i].size()==0:
			label(DISTRICTS[i][int(n/BASE_RISES[i].size())],Vector2(400,y-225),23)
	for branch_id in range(3):
		var main_index=branch_indices[branch_id];var r=platforms[main_index]
		# Place the nook away from the next main shelf, avoiding intercepted jumps.
		var direction=-1 if route_x(i,main_index+1)>=r.get_center().x else 1
		var x=r.get_center().x+245*direction
		var side=Rect2(x-90,r.position.y-70,180,22);body(side,true);platforms.append(side)
		branches.append({"rect":side,"return_index":main_index,"leaf_id":[4,12,20][branch_id]})
		ledges.append(painted_ledge(side,"ruler" if branch_id==1 else "plank"))
		prop("school_props_plant",Vector2(x-57,side.position.y),68)
		pickup("leaf",[4,12,20][branch_id],"collectibles_leaf_token",Vector2(x+38,side.position.y-22),48)
		if branch_id==0:pickup("token",0,"collectibles_bark_token",Vector2(x-12,side.position.y-62),58)
		label("DISCOVERY NOOK",Vector2(x-85,side.position.y+42),14)
	var q=platforms[RISES[i].size()-2]
	quest={"pos":Vector2(q.get_center().x,q.position.y),"sprite":prop(ASSETS[i],Vector2(q.get_center().x,q.position.y),90)}
	exit=platforms[RISES[i].size()-1].get_center();exit.y=top
	prop("school_props_noticeboard" if i==0 else "school_props_desk",exit,155)
	label("DELIVERY POINT",exit+Vector2(-100,-170),18)
	bark=Art.game_actor("bark_actions_idle");bark.scale=Vector2.ONE*.20;bark.position=Vector2(410,650);bark.z_index=4;add_child(bark)
	for actor in [get_parent().player,bark]:
		var shadow=load("res://scripts/prop_shadow.gd").new()
		shadow.name=("LibraryContactShadow" if i==0 else "WorldContactShadow")+("Bark" if actor==bark else "Mark")
		shadow.source=actor;shadow.follows=true
		shadow.half_width=24 if actor==bark else 20;shadow.softness=4;shadow.opacity=.22;shadow.z_index=0;add_child(shadow)
	refresh()
func route_x(i,n):
	var section=int(n/BASE_CENTERS[i].size());return BASE_CENTERS[i][n%BASE_CENTERS[i].size()]+[0,35,-25][section]
func painted_ledge(rect,kind):
	var l=load("res://scripts/variety_platform.gd").new();l.position=rect.position;l.width=rect.size.x;l.kind=kind;l.library_style=level==0;l.z_index=1;add_child(l);return l
func body(r: Rect2, one_way: bool):
	var b=StaticBody2D.new();b.collision_layer=1;b.collision_mask=2
	var c=CollisionShape2D.new();var s=RectangleShape2D.new();s.size=r.size;c.shape=s;c.position=r.get_center();c.one_way_collision=one_way;c.one_way_collision_margin=10;b.add_child(c);add_child(b)
func prop(id,pos,size):
	var s=Art.prop(id,size);s.position=pos;s.z_index=2;add_child(s);return s
func pickup(kind,id,asset,pos,size):pickups.append({"kind":kind,"id":id,"pos":pos,"sprite":prop(asset,pos,size)})
func label(value,pos,size):
	var l=Label.new();l.text=value;l.position=pos;l.size=Vector2(350,45);l.add_theme_font_override("font",Art.font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("fff2ce"));l.add_theme_color_override("font_shadow_color",Color("203849"));l.add_theme_constant_override("shadow_offset_y",2);l.z_index=2;add_child(l)
func support_y(x,y):
	var result=650.0
	for p in platforms:
		if x>=p.position.x-6 and x<=p.end.x+6 and p.position.y>=y-8:result=minf(result,p.position.y)
	return result
func remember_landing(at):
	if absf(at.y-650)<6:last_safe=Vector2(clampf(at.x,100,1500),647);safe_shelf=0
	for n in range(RISES[level].size()):
		var r=platforms[n]
		if absf(at.y-r.position.y)<6 and at.x>=r.position.x-15 and at.x<=r.end.x+15:last_safe=Vector2(r.get_center().x,r.position.y-3);safe_shelf=n+1
	for branch in branches:
		if absf(at.y-branch.rect.position.y)<6:
			var parent=platforms[branch.return_index];last_safe=Vector2(parent.get_center().x,parent.position.y-3);safe_shelf=branch.return_index+1
func advance_hazards(delta,player):
	clock+=delta;enemy_grace=maxf(0,enemy_grace-delta)
	for e in enemies:
		e.reduced_motion=reduced_motion;e.advance(delta)
		if not e.introduced and player.position.distance_to(e.position)<240:
			e.introduced=true;get_parent().toast(e.tip(),2)
		var player_box=Rect2(player.position+Vector2(-11,-72),Vector2(22,64))
		if not Mega.prefs.calm and enemy_grace<=0 and player_box.intersects(e.hit_box()):get_parent().recover_encounter(e.tip());break
func refresh():
	var r=Mega.runs[level]
	for p in pickups:p.sprite.visible=not (p.id in r.leaves if p.kind=="leaf" else r.token)
	if not quest.is_empty():quest.sprite.visible=not r.quest
	for c in checkpoints:c.sprite.texture=Art.tex("ui_parts_reward_check" if c.index<=r.checkpoint else "ui_parts_hint_bulb")
	if is_instance_valid(scenery):scenery.queue_redraw()
func _process(_delta):
	if get_parent().get("busy")==true:return
	for l in ledges:l.reduced_motion=reduced_motion
	for p in pickups:p.sprite.position=p.pos if reduced_motion else p.pos+Vector2(0,sin(clock*2+p.id)*2)
	scenery.reduced_motion=reduced_motion
