extends Node2D
# A separate, editable inspection room. It never writes campaign progress.
const MODES=["Idle","Walk","Run","Jump","Bark spring","Talk","Cheer"]
var mark
var bark
var elapsed=0.0
var total=0.0
var current=0
var paused=false
var slow=false
var showcase=false
var points=false
var headline: Label
var caption: Label
var pause_button: Button
var speed_button: Button
var point_button: Button
var modes=[]
var auto_stage=-1
var last_grounded=true
var turntable=false
var orbit_button: Button

func _ready():
	showcase="--showcase" in OS.get_cmdline_user_args()
	label("MARK & BARK",Rect2(44,20,650,48),36)
	label("CHARACTER 2.0  /  3D PERFORMANCE STUDIO  /  3.9",Rect2(47,72,900,30),17,Color("8a713f"))
	button("All adventures",Rect2(1040,32,192,52),func():Adventures.go(Adventures.HOME))
	headline=label("",Rect2(400,24,620,48),22);headline.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label("MARK",Rect2(78,190,270,30),21)
	label("Curiosity, courage & a very good landing.",Rect2(78,226,166,100),16,Color("6d725f"))
	label("BARK",Rect2(1040,190,150,30),21)
	label("Big ideas. Questionable advice. Excellent springiness.",Rect2(1040,226,150,110),16,Color("6d725f"))
	mark=Art.character("young_actions_idle");mark.position=Vector2(420,558);mark.scale=Vector2.ONE*.80;add_child(mark)
	bark=Art.character("bark_actions_idle");bark.position=Vector2(830,558);bark.scale=Vector2.ONE*1.0;add_child(bark)
	if Progress.settings.get("characters_3d",true):mark.scale=Vector2.ONE*.73;bark.scale=Vector2.ONE*.88
	caption=label("",Rect2(110,565,1060,35),17);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for n in range(MODES.size()):
		modes.append(button(MODES[n],Rect2(44+n*171,613,162,42),func():choose(n)))
	pause_button=button("Pause [Space]",Rect2(44,667,205,38),toggle_pause)
	speed_button=button("Speed: 1×",Rect2(261,667,172,38),toggle_speed)
	point_button=button("Joints: off [P]",Rect2(445,667,207,38),toggle_points)
	button("Next frame",Rect2(664,667,174,38),next_frame)
	orbit_button=button("Turntable [O]",Rect2(858,667,174,38),toggle_turntable)
	label("1–7: pose · Esc: game",Rect2(1044,674,195,27),14,Color("6d725f"))
	choose(0);queue_redraw();call_deferred("settle_controls")

func settle_controls():
	# Wrapped-label minimum heights settle after their final width and font do.
	for pass_index in range(2):
		await get_tree().process_frame
		for control in get_children():
			if control is Control and control.has_meta("studio_rect"):
				var r: Rect2=control.get_meta("studio_rect");control.position=r.position;control.size=r.size

func _draw():
	draw_rect(Rect2(0,0,1280,720),Color("f3ead4"))
	draw_style_box(panel_style(),Rect2(36,121,1208,481))
	draw_line(Vector2(80,558),Vector2(1200,558),Color("d6c59c"),2,true)
	for x in [420,830]:
		for n in range(4):draw_ellipse(Vector2(x,558),Vector2(77-n*10,10-n),Color(.17,.24,.21,.026))

func draw_ellipse(center,radius,colour):
	var vertices=PackedVector2Array()
	for n in range(48):vertices.append(center+Vector2(cos(n*TAU/48)*radius.x,sin(n*TAU/48)*radius.y))
	draw_colored_polygon(vertices,colour)
func panel_style():
	var s=StyleBoxFlat.new();s.bg_color=Color("fff9e9");s.set_corner_radius_all(22);s.border_color=Color("dfc88e");s.set_border_width_all(2);return s
func label(value,r,font_size=20,colour=Color("203849")):
	var c=Label.new();c.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;c.mouse_filter=Control.MOUSE_FILTER_IGNORE;c.add_theme_font_override("font",Art.font);c.add_theme_font_size_override("font_size",font_size);c.add_theme_color_override("font_color",colour);c.text=value;add_child(c);c.position=r.position;c.size=r.size;c.set_meta("studio_rect",r);return c
func button(value,r,action):
	var c=Button.new();c.text=value;c.position=r.position;c.size=r.size;c.add_theme_font_override("font",Art.font);c.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed","focus"]:
		var s=panel_style();s.set_corner_radius_all(10)
		if state=="hover":s.bg_color=Color("eadeb6")
		if state=="pressed":s.bg_color=Color("d8c17f")
		if state=="focus":s.bg_color=Color.TRANSPARENT;s.set_border_width_all(3)
		c.add_theme_stylebox_override(state,s)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:c.add_theme_color_override(state,Color("203849"))
	c.pressed.connect(action);add_child(c);c.set_meta("studio_rect",r);return c

func choose(n):
	current=posmod(n,MODES.size());elapsed=0;last_grounded=true
	for actor in [mark,bark]:actor.reset_motion();actor.frozen=paused
	for i in range(modes.size()):modes[i].disabled=i==current
	headline.text=["A little breath. A bright idea.","A stroll with a very opinionated friend.","Tiny feet. Enormous plans.","Reach, tuck, float… and land softly.","One jump. Two friends. A leafy launch.","“What could possibly go slightly sideways?”","Big idea? Big celebration."][current]
	caption.text=["Heads, shoulders and clothing settle gently; feet stay planted.","Distance-matched poses with a little arm and knee follow-through.","A lively run, loose wrists and swaying leaves.","The original key pose, brought to life through separate joints.","Contact, release and recovery • try the real spring in the game.","Blinking, looking, eyebrows and small mouth movements.","Mark beams; Bark cheers with his whole canopy."][current]
	update_actors()
func toggle_pause():
	paused=not paused;pause_button.text="Resume [Space]" if paused else "Pause [Space]"
	for actor in [mark,bark]:actor.frozen=paused
func toggle_speed():
	slow=not slow;speed_button.text="Speed: ½×" if slow else "Speed: 1×"
	for actor in [mark,bark]:actor.playback_rate=.5 if slow else 1.0
func toggle_points():
	points=not points;point_button.text="Joints: on [P]" if points else "Joints: off [P]"
	mark.show_points=points;bark.show_points=points
func toggle_turntable():
	turntable=not turntable
	orbit_button.text="Turntable: on" if turntable else "Turntable [O]"
	if not turntable:
		for actor in [mark,bark]:
			if is_instance_valid(actor.character3d):actor.character3d.inspection_yaw=0;actor.character3d.request_frame()
func next_frame():
	if not paused:toggle_pause()
	elapsed+=(1.0/60.0)*(.5 if slow else 1.0);update_actors()
	for actor in [mark,bark]:actor.frozen=false;actor._process(1.0/60.0);actor.frozen=true
func _process(delta):
	if not is_instance_valid(mark):return
	if showcase:
		total+=delta
		var stage=int(total/3.0)
		if stage>=8:get_tree().quit();return
		if stage!=auto_stage:
			auto_stage=stage
			if stage<7:choose(stage)
			else:choose(5);toggle_points()
	if not paused:
		elapsed+=delta*(.5 if slow else 1.0);update_actors()
		if turntable and not Progress.settings.reduced_motion:
			for actor in [mark,bark]:
				if is_instance_valid(actor.character3d) and actor.character3d.active:actor.character3d.inspection_yaw+=delta*.62
func update_actors():
	var mark_id="young_actions_idle";var bark_id="bark_actions_idle";var state="idle";var grounded=true;var speed=Vector2.ZERO;var height=0.0
	var cadence=elapsed*(7.6 if current==1 else 11.8)
	if current in [1,2]:
		var part="walk" if current==1 else "run";var i=int(elapsed*(5.0 if current==1 else 7.0))%4
		var frames=["stride_a","passing","stride_b","passing"]
		mark_id="young_actions_"+part+"_"+(["stride_a","passing","stride_b","flight"][i] if current==2 else frames[i]);bark_id="bark_actions_"+part+"_"+frames[i]
		state=part;speed.x=140 if current==1 else 260
	elif current in [3,4]:
		var t=fmod(elapsed,2.5)
		if t<.16:mark_id="young_actions_crouch";state="anticipate"
		elif t<1.50:
			var u=(t-.16)/1.34;mark_id="young_actions_jump";bark_id="bark_actions_hop";grounded=false;height=sin(u*PI)*70;speed=Vector2(130,-cos(u*PI)*300);state="jump" if current==3 else "spring_release"
		elif t<1.70:mark_id="young_actions_crouch";state="land"
		if current==4 and t<.16:bark_id="bark_actions_hop";state="spring_contact"
	elif current==5:mark_id="young_actions_notebook";bark_id="bark_actions_hint";state="talk"
	elif current==6:mark_id="young_actions_jump";bark_id="bark_actions_cheer";state="celebrate"
	mark.texture=Art.tex(mark_id);bark.texture=Art.tex(bark_id)
	if is_instance_valid(mark.character3d) and mark.character3d.active:height*=.74
	mark.position.y=558-height;bark.position.y=558-height*.55
	if grounded and not last_grounded:
		mark.land(.7);bark.land(.5)
	last_grounded=grounded
	for actor in [mark,bark]:actor.drive(state,grounded,speed,cadence)
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):return
	if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_7:choose(event.physical_keycode-KEY_1)
	elif event.physical_keycode==KEY_SPACE:toggle_pause()
	elif event.physical_keycode==KEY_P:toggle_points()
	elif event.physical_keycode==KEY_O:toggle_turntable()
	elif event.physical_keycode==KEY_ESCAPE:Adventures.go(Adventures.HOME)
