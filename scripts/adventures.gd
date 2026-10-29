extends Node2D

var mark: Sprite2D
var bark: Sprite2D
var music_player: AudioStreamPlayer
var story_button: Button
var climb_button: Button
var paint_toggle: CheckButton
var closing=false

func _ready() -> void:
	get_tree().auto_accept_quit=false
	var background=Sprite2D.new()
	background.texture=Art.tex("garden_hub");background.centered=false
	background.scale=Vector2(1280.0/background.texture.get_width(),720.0/background.texture.get_height())
	add_child(background)
	var shade=ColorRect.new();shade.size=Vector2(1280,720);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=load("res://shaders/adventure_menu.gdshader");shade.material=material;add_child(shade)
	label(self,"MARK & BARK",Rect2(48,28,780,65),47,"fff3d3")
	label(self,"Small friends. Big possibilities.",Rect2(52,101,760,35),23,"f0ce83")
	card(Rect2(48,166,680,213))
	picture("school_hub",Rect2(65,184,202,177))
	label(self,"THE BIG IDEA",Rect2(292,184,407,40),29)
	label(self,"The school, discovery garden and invention workshop. Follow the story, explore and build a paper-plane machine.",Rect2(294,234,400,74),19)
	story_button=button("Continue story" if Progress.tutorial_done else "Start the story",Rect2(292,317,409,44),func():Adventures.go(Adventures.STORY,"start_continue"),true)
	card(Rect2(48,399,680,168))
	picture("workshop_hub_v4",Rect2(65,416,202,133))
	label(self,"THE GIANT CLIMBS",Rect2(292,412,407,38),26)
	label(self,"Three school and home climbs.\n84 shelves, 72 leaves and one leafy spring.",Rect2(294,457,400,51),18)
	climb_button=button("Continue climb" if Mega.intro_done else "Start the climbs",Rect2(292,512,409,38),func():Adventures.go(Adventures.CLIMBS,"start"))
	button("Watch the campus film",Rect2(48,589,329,48),func():Adventures.go(Adventures.STORY,"watch_film"))
	button("Character studio",Rect2(397,589,331,48),func():Adventures.go(Adventures.STUDIO))
	paint_toggle=CheckButton.new();paint_toggle.name="PaintedCharacters";paint_toggle.text="Original painted characters";paint_toggle.position=Vector2(48,654);paint_toggle.size=Vector2(410,40)
	paint_toggle.button_pressed=Progress.settings.get("painted_characters",true)
	paint_toggle.add_theme_icon_override("checked",load("res://assets/ui_toggle_on.svg"));paint_toggle.add_theme_icon_override("unchecked",load("res://assets/ui_toggle_off.svg"))
	paint_toggle.add_theme_font_override("font",Art.font);paint_toggle.add_theme_font_size_override("font_size",18)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:paint_toggle.add_theme_color_override(state,Color("fff3d3"))
	paint_toggle.toggled.connect(func(value):Progress.settings.painted_characters=value;Progress.save_game())
	add_child(paint_toggle)
	label(self,"Off: extra facial and limb movement",Rect2(470,660,350,28),15,"e3d9b9")
	mark=Art.game_actor("young_actions_notebook");mark.position=Vector2(940,610);mark.scale=Vector2.ONE*.66;add_child(mark)
	bark=Art.game_actor("bark_actions_cheer");bark.position=Vector2(1150,610);bark.scale=Vector2.ONE*.63;add_child(bark)
	label(self,"Two adventures.\nOne very opinionated friend.",Rect2(815,178,405,100),27,"fff3d3")
	music_player=AudioStreamPlayer.new();music_player.stream=load("res://assets/campus_music.wav");music_player.volume_db=linear_to_db(maxf(.0001,Progress.settings.volume*.28));add_child(music_player)
	if Progress.settings.music and Progress.settings.volume>0:music_player.play()
	story_button.grab_focus()
	call_deferred("settle_controls")

func settle_controls():
	for pass_index in range(2):
		await get_tree().process_frame
		for control in get_children():
			if control is Control and control.has_meta("menu_rect"):
				var rect: Rect2=control.get_meta("menu_rect");control.position=rect.position;control.size=rect.size

func stop_audio():
	if is_instance_valid(music_player):music_player.stop();music_player.stream=null

func drain_audio():
	stop_audio()
	var deadline=Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<deadline:await get_tree().process_frame

func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST and not closing:
		closing=true
		await drain_audio()
		get_tree().quit()

func _exit_tree():stop_audio()

func card(rect):
	var panel=Panel.new();panel.position=rect.position;panel.size=rect.size
	var style=StyleBoxFlat.new();style.bg_color=Color("f4ecd8f5");style.border_color=Color("d6b264");style.set_border_width_all(2);style.set_corner_radius_all(18);style.shadow_color=Color(0,0,0,.25);style.shadow_size=8
	panel.add_theme_stylebox_override("panel",style);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)

func picture(id,rect):
	var art=TextureRect.new();art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.clip_contents=true;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.texture=Art.tex(id);add_child(art);art.position=rect.position;art.size=rect.size;art.set_meta("menu_rect",rect)

func label(parent,value,rect,font_size=22,colour="203849"):
	var text=Label.new();text.text=value;text.position=rect.position;text.size=rect.size;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_override("font",Art.font);text.add_theme_font_size_override("font_size",font_size);text.add_theme_color_override("font_color",Color(colour));parent.add_child(text);text.position=rect.position;text.size=rect.size;text.set_meta("menu_rect",rect);return text

func button(value,rect,action,primary=false):
	var control=Button.new();control.text=value;control.position=rect.position;control.size=rect.size;control.add_theme_font_override("font",Art.font);control.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","focus"]:
		var style=StyleBoxFlat.new();style.bg_color=Color("203849" if primary else "fff3d3");style.border_color=Color("d6b264");style.set_border_width_all(2);style.set_corner_radius_all(12)
		if state=="hover":style.bg_color=Color("41616b" if primary else "e9d49a")
		if state=="pressed":style.bg_color=Color("304955" if primary else "d8bf83")
		if state=="focus":style.bg_color=Color.TRANSPARENT;style.set_border_width_all(4)
		control.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:control.add_theme_color_override(state,Color("fff3d3" if primary else "203849"))
	control.pressed.connect(action);add_child(control);control.position=rect.position;control.size=rect.size;control.set_meta("menu_rect",rect);return control
