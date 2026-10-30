extends Node2D

var mark: Sprite2D
var bark: Sprite2D
var music_player: AudioStreamPlayer
var story_button: Button
var climb_button: Button
var paint_toggle: CheckButton
var three_d_toggle: CheckButton
var closing=false
var audio_stopped=false
var settings_overlay: Control
var settings_button: Button
var save_notice: Label
var quit_prompt: CanvasLayer
var whimsy

func _ready() -> void:
	get_tree().auto_accept_quit=false
	var background=Sprite2D.new()
	background.texture=Art.tex("garden_hub");background.centered=false
	background.scale=Vector2(1280.0/background.texture.get_width(),720.0/background.texture.get_height())
	add_child(background)
	var shade=ColorRect.new();shade.size=Vector2(1280,720);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=load("res://shaders/adventure_menu.gdshader");shade.material=material;add_child(shade)
	whimsy=load("res://scripts/whimsy_layer.gd").new();whimsy.name="WhimsyLayer";whimsy.context="menu";whimsy.controller=self;add_child(whimsy)
	label(self,"MARK & BARK",Rect2(48,28,780,65),47,"fff3d3")
	label(self,"Small friends. Big possibilities.",Rect2(52,101,760,35),23,"f0ce83")
	label(self,"FULL OF CHARACTER · 4.2",Rect2(820,126,400,28),16,"f4d39a")
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
	button("Campus film",Rect2(48,589,212,48),func():Adventures.go(Adventures.STORY,"watch_film"))
	button("Character studio",Rect2(282,589,212,48),func():Adventures.go(Adventures.STUDIO))
	settings_button=button("Settings",Rect2(516,589,212,48),show_settings)
	paint_toggle=CheckButton.new();paint_toggle.name="PaintedCharacters";paint_toggle.text="Original painted characters";paint_toggle.position=Vector2(48,654);paint_toggle.size=Vector2(410,40)
	paint_toggle.button_pressed=Progress.settings.get("painted_characters",true)
	paint_toggle.add_theme_icon_override("checked",load("res://assets/ui_toggle_on.svg"));paint_toggle.add_theme_icon_override("unchecked",load("res://assets/ui_toggle_off.svg"))
	paint_toggle.add_theme_font_override("font",Art.font);paint_toggle.add_theme_font_size_override("font_size",18)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:paint_toggle.add_theme_color_override(state,Color("fff3d3"))
	paint_toggle.toggled.connect(func(value):Progress.set_setting("painted_characters",value))
	add_child(paint_toggle)
	# Keep the legacy switch API for old saves/tools; the new visible switch is
	# explicit about 3D, with both painting modes available in shared Settings.
	paint_toggle.hide()
	three_d_toggle=CheckButton.new();three_d_toggle.name="Characters3D";three_d_toggle.text="Character 2.0 · 3D models";three_d_toggle.position=Vector2(48,654);three_d_toggle.size=Vector2(410,40)
	three_d_toggle.button_pressed=bool(Progress.settings.get("characters_3d",true))
	three_d_toggle.add_theme_icon_override("checked",load("res://assets/ui_toggle_on.svg"));three_d_toggle.add_theme_icon_override("unchecked",load("res://assets/ui_toggle_off.svg"))
	three_d_toggle.add_theme_font_override("font",Art.font);three_d_toggle.add_theme_font_size_override("font_size",18)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:three_d_toggle.add_theme_color_override(state,Color("fff3d3"))
	three_d_toggle.toggled.connect(func(value):Progress.set_setting("characters_3d",value))
	add_child(three_d_toggle)
	label(self,"Painted styles remain in Settings",Rect2(470,660,350,28),15,"e3d9b9")
	mark=Art.game_actor("young_actions_notebook");mark.position=Vector2(940,610);mark.scale=Vector2.ONE*.66;add_child(mark)
	bark=Art.game_actor("bark_actions_cheer");bark.position=Vector2(1150,610);bark.scale=Vector2.ONE*.63;add_child(bark)
	for actor in [mark,bark]:
		var shadow=preload("res://scripts/prop_shadow.gd").new()
		shadow.name="HomeContactShadow"+("Mark" if actor==mark else "Bark")
		shadow.source=actor;shadow.anchor=actor.position;shadow.half_width=45 if actor==mark else 52
		shadow.softness=8;shadow.opacity=.19;add_child(shadow);move_child(shadow,actor.get_index())
	label(self,"Two adventures.\nOne very opinionated friend.",Rect2(815,178,405,100),27,"fff3d3")
	music_player=AudioStreamPlayer.new();music_player.stream=preload("res://scripts/audio_loops.gd").stream("campus_music");music_player.volume_db=-80;add_child(music_player)
	if music_player.stream:music_player.play()
	save_notice=label(self,"",Rect2(48,699,1184,19),13,"fff3d3")
	Progress.settings_changed.connect(apply_settings)
	Progress.save_status_changed.connect(update_save_notice)
	Mega.save_status_changed.connect(update_save_notice)
	apply_settings();update_save_notice()
	story_button.grab_focus()
	call_deferred("settle_controls")

func settle_controls():
	if not is_inside_tree():return
	var tree=get_tree()
	for pass_index in range(2):
		await tree.process_frame
		if not is_inside_tree() or is_queued_for_deletion():return
		for control in get_children():
			if control is Control and control.has_meta("menu_rect"):
				var rect: Rect2=control.get_meta("menu_rect");control.position=rect.position;control.size=rect.size

func stop_audio():
	audio_stopped=true
	if is_instance_valid(music_player):music_player.stop();music_player.stream=null

func apply_settings(_key="",_value=null):
	paint_toggle.set_pressed_no_signal(bool(Progress.settings.painted_characters))
	three_d_toggle.set_pressed_no_signal(bool(Progress.settings.get("characters_3d",true)))
	if not is_instance_valid(music_player) or audio_stopped:return
	music_player.volume_db=linear_to_db(maxf(.0001,Progress.settings.volume*.28))
	music_player.stream_paused=not Progress.settings.music or Progress.settings.volume<=0

func update_save_notice(_ok=true):
	if not is_instance_valid(save_notice):return
	save_notice.text="Progress could not be saved. Keep this game open and try again in Settings." if not Progress.last_save_ok or not Mega.last_save_ok else "Recovered your previous saved adventure." if Progress.recovered_backup or Mega.recovered_backup else ""

func show_settings():
	if is_instance_valid(settings_overlay):return
	settings_overlay=Control.new();settings_overlay.size=Vector2(1280,720);settings_overlay.z_index=40;add_child(settings_overlay)
	var veil=ColorRect.new();veil.size=Vector2(1280,720);veil.color=Color(.05,.10,.12,.72);settings_overlay.add_child(veil)
	var panel=Panel.new();panel.position=preload("res://scripts/shared_settings.gd").MENU_RECT.position;panel.size=preload("res://scripts/shared_settings.gd").MENU_RECT.size;settings_overlay.add_child(panel)
	var content=preload("res://scripts/shared_settings.gd").new();content.done=close_settings;panel.add_child(content)

func close_settings():
	if is_instance_valid(settings_overlay):settings_overlay.queue_free()
	settings_overlay=null;settings_button.grab_focus()

func drain_audio():
	stop_audio()
	var deadline=Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<deadline:await get_tree().process_frame

func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST:request_quit()

func request_quit():
	if closing or (is_instance_valid(quit_prompt) and not quit_prompt.is_queued_for_deletion()):return
	if not preload("res://scripts/save_exit.gd").save_all():
		quit_prompt=preload("res://scripts/save_exit.gd").new();quit_prompt.retry=request_quit;quit_prompt.quit_anyway=finish_quit;add_child(quit_prompt);return
	await finish_quit()

func finish_quit():
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
