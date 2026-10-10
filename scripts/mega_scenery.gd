extends Node2D
var level=0
var reduced_motion=false
var clock=0.0
func _process(d):
	clock+=d;queue_redraw()
func box(r,c,rad=8):
	if rad>0:
		var shade=StyleBoxFlat.new();shade.bg_color=Color(.16,.13,.09,.11);shade.set_corner_radius_all(rad)
		for n in range(3):draw_style_box(shade,Rect2(r.position+Vector2(3+n*2,5+n*2),r.size))
	var s=StyleBoxFlat.new();s.bg_color=Color(c);s.corner_radius_top_left=rad;s.corner_radius_top_right=rad;s.corner_radius_bottom_left=rad;s.corner_radius_bottom_right=rad;s.border_color=Color("705a3c");s.set_border_width_all(2)
	draw_style_box(s,r)
	if c in ["81653e","897254","af824a","a07a46","a38c65","b5935a","c5a977","ae9063","c4a56b","b79a62"] and r.size.y>25:
		for k in range(8):
			var y=r.position.y+10+k*(r.size.y-20)/8
			var points=PackedVector2Array()
			for x in range(12,int(r.size.x)-11,12):points.append(Vector2(r.position.x+x,y+sin(x*.04+k)*2))
			if points.size()>1:draw_polyline(points,Color(.33,.23,.12,.11),1)
		draw_line(r.position+Vector2(10,5),r.position+Vector2(r.size.x-10,5),Color(1,.92,.67,.25),2)
func sprite(id,foot,width,alpha=1.0):
	var t=Art.tex(id);var size=t.get_size()*width/maxf(t.get_width(),t.get_height());draw_texture_rect(t,Rect2(foot-Vector2(size.x/2,size.y),size),false,Color(1,1,1,alpha))
func window_at(x,y):
	box(Rect2(x,y,260,225),"b5935a",14);box(Rect2(x+14,y+14,232,197),"bfd3cb",8)
	for j in range(6):
		draw_circle(Vector2(x+35+j*39,y+85-sin(j)*22),32,Color("dde7d4"))
	draw_line(Vector2(x+130,y+15),Vector2(x+130,y+211),Color("e9d9b5"),11);draw_line(Vector2(x+14,y+117),Vector2(x+246,y+117),Color("e9d9b5"),11)
	box(Rect2(x-15,y+215,290,20),"c5a977",4)
	var beam=PackedVector2Array([Vector2(x+15,y+20),Vector2(x+245,y+20),Vector2(x+395,y+510),Vector2(x+210,y+510)])
	draw_colored_polygon(beam,Color(1,.94,.68,.08))
func _draw():
	texture_repeat=CanvasItem.TEXTURE_REPEAT_MIRROR
	var wall=Color("e6d8b7") if level==0 else Color("c8d2c0") if level==1 else Color("ba9970")
	draw_rect(Rect2(0,-2400,1600,3100),wall)
	for y in range(-2400,700,380):
		if level==2:
			draw_texture_rect(Art.tex("oak_floor"),Rect2(0,y,1600,380),true,Color(.67,.55,.43))
		else:
			for x in range(0,1600,70):draw_line(Vector2(x,y),Vector2(x,y+380),Color(.48,.42,.29,.07),2)
		box(Rect2(0,y+330,1600,28),"a38c65",0)
		for x in [120,1220]:window_at(x,y+45)
		if level==0:
			sprite("school_props_bookcase",Vector2(150,y+330),310)
			sprite("school_props_navy_locker",Vector2(1380,y+330),265)
			if y==260:
				box(Rect2(520,y+65,560,210),"54705e",12)
				for k in range(4):draw_line(Vector2(565,y+110+k*35),Vector2(1010-k*42,y+110+k*35),Color(.93,.92,.75,.28),2)
			elif y<260:
				# Upper library alcoves replace repeated blackboards.
				box(Rect2(410,y+30,740,280),"ae9063",12)
				box(Rect2(427,y+45,706,242),"8a795e",8)
				for k in range(9):
					var height=130+(k*37)%95
					var color=["536d69","b29965","768b88","a97c57"][k%4]
					box(Rect2(448+k*73,y+283-height,56,height),color,5)
					draw_line(Vector2(456+k*73,y+263),Vector2(493+k*73,y+263),Color("e9d4a2"),3)
		elif level==1:
			box(Rect2(1090,y+80,360,245),"897254",16)
			box(Rect2(1104,y+94,160,218),"c4a56b",8);box(Rect2(1278,y+94,156,218),"b79a62",8)
			draw_circle(Vector2(1244,y+203),7,Color("f2d385"));draw_circle(Vector2(1298,y+203),7,Color("f2d385"))
			box(Rect2(120,y+75,235,180),"fff1d6",8)
			for k in range(3):draw_circle(Vector2(165+k*60,y+130+sin(k)*30),24,Color("d5ba76"))
			sprite("school_props_plant",Vector2(150,y+330),130)
		else:
			for x in [70,1460]:box(Rect2(x,y,50,380),"65503b",0)
			draw_line(Vector2(110,y),Vector2(790,y+280),Color("71583c"),30);draw_line(Vector2(1490,y),Vector2(810,y+280),Color("71583c"),30)
			sprite("collectibles_books",Vector2(210,y+330),175)
			sprite("school_props_lamp",Vector2(1390,y+270),150)
	# Anchored foreground furniture grounds the miniature scale.
	draw_texture_rect(Art.tex("oak_floor"),Rect2(0,650,1600,150),true)
	if level==0:
		sprite("school_props_desk",Vector2(180,650),350);sprite("school_props_bookcase",Vector2(1300,650),470)
		sprite("school_props_noticeboard",Vector2(1030,630),200)
	elif level==1:
		# Oak bed, quilt, pillow, toy chest and writing desk: recognisably a home.
		box(Rect2(65,350,400,290),"81653e",20)
		draw_colored_polygon(PackedVector2Array([Vector2(465,360),Vector2(495,390),Vector2(495,650),Vector2(465,638)]),Color("665135"))
		box(Rect2(80,422,425,180),"eee2bd",30)
		draw_rect(Rect2(89,606,405,28),Color("957449"))
		for x in [97,454]:box(Rect2(x,620,22,30),"81653e",5)
		box(Rect2(92,438,115,70),"fff5dc",24);box(Rect2(225,433,270,165),"607f83",18)
		for x in range(250,490,35):draw_line(Vector2(x,440),Vector2(x,590),Color("97b0a4"),2)
		for y in range(460,590,30):draw_line(Vector2(230,y),Vector2(488,y),Color("849d95"),2)
		for x in range(243,480,35):draw_circle(Vector2(x,449),1.5,Color("d9e0c3"))
		box(Rect2(1140,465,355,185),"af824a",14);draw_line(Vector2(1150,518),Vector2(1485,518),Color("e0bd78"),8)
		sprite("school_props_desk",Vector2(880,650),370);sprite("collectibles_mug",Vector2(920,485),55)
	else:
		for x in [130,1210]:
			box(Rect2(x,455,260,195),"a07a46",10);draw_line(Vector2(x+20,475),Vector2(x+240,630),Color("dfbf86"),14)
		sprite("school_props_desk",Vector2(820,650),420);sprite("school_props_science_volcano",Vector2(845,454),115)
		sprite("collectibles_pencil",Vector2(1070,650),340)
	if not reduced_motion:
		for i in range(32):
			var x=100+fmod(i*137+sin(clock*.35+i)*12,1400)
			var y=-2100+fmod(i*113+clock*6,2750)
			draw_circle(Vector2(x,y),1.5,Color(1,.96,.8,.25))
