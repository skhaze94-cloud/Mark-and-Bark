extends Control

const MENU_RECT=Rect2(270,55,740,610)
const LABELS={"music":"Background music","reduced_motion":"Reduced motion","touch":"Always show touch controls","painted_characters":"Original painted characters","calm":"Calm climb (climbing adventure)"}
var done: Callable
var volume_slider: HSlider
var volume_label: Label
var save_notice: Label
var back_button: Button
var toggles={}
var style_selector: OptionButton
const STYLE_NAMES=["3D storybook", "Original painting", "Articulated painting"]

func _ready():
	name="SharedSettings"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new();style.bg_color=Color("f4ecd8");style.border_color=Color("d3ac53");style.set_border_width_all(3);style.set_corner_radius_all(18);style.shadow_color=Color(0,0,0,.24);style.shadow_size=12
	get_parent().add_theme_stylebox_override("panel",style)
	text("SETTINGS & CONTROLS",Rect2(30,22,680,44),29)
	text("Sound volume",Rect2(30,88,170,38),22)
	volume_slider=HSlider.new();volume_slider.name="Volume";volume_slider.position=Vector2(205,90);volume_slider.size=Vector2(345,36);volume_slider.min_value=0;volume_slider.max_value=1;volume_slider.step=.05;add_child(volume_slider)
	volume_label=text("",Rect2(585,91,100,32),21)
	var keys=LABELS.keys()
	for i in range(keys.size()):
		var key=keys[i];var toggle=CheckButton.new();toggle.name="CalmClimb" if key=="calm" else key.to_pascal_case();toggle.position=Vector2(28,144+i*51);toggle.size=Vector2(682,44);toggle.add_theme_font_override("font",Art.font);toggle.add_theme_font_size_override("font_size",21)
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:toggle.add_theme_color_override(state,Color("203849"))
		toggle.add_theme_icon_override("checked",load("res://assets/ui_toggle_on.svg"));toggle.add_theme_icon_override("unchecked",load("res://assets/ui_toggle_off.svg"));toggles[key]=toggle;add_child(toggle)
		toggle.toggled.connect(func(value):change_toggle(key,value))
		if key=="painted_characters":toggle.hide()
	text("Character style",Rect2(30,300,220,38),21)
	style_selector=OptionButton.new();style_selector.name="CharacterStyle";style_selector.position=Vector2(260,297);style_selector.size=Vector2(450,44)
	style_selector.add_theme_font_override("font",Art.font);style_selector.add_theme_font_size_override("font_size",20)
	for value in STYLE_NAMES:style_selector.add_item(value)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:style_selector.add_theme_color_override(state,Color("203849"))
	for state in ["normal","hover","pressed","focus"]:
		var surface=StyleBoxFlat.new();surface.bg_color=Color("fff5df" if state!="hover" else "e8d9b0");surface.border_color=Color("b59b67");surface.set_border_width_all(2);surface.set_corner_radius_all(10)
		style_selector.add_theme_stylebox_override(state,surface)
	add_child(style_selector);style_selector.item_selected.connect(select_character_style)
	text("A/D or arrows: move · Space twice: jump · E: use · H: hint\nN: notebook · Esc: back/pause · Climbs: R for checkpoint\nTouch: hold an arrow and tap Jump twice.",Rect2(30,414,680,64),17)
	save_notice=text("",Rect2(30,487,680,44),17)
	back_button=Button.new();back_button.name="Back";back_button.text="Back";back_button.position=Vector2(240,545);back_button.size=Vector2(260,50);back_button.add_theme_font_override("font",Art.font);back_button.add_theme_font_size_override("font_size",21)
	for state in ["normal","hover","pressed","focus"]:
		var surface=StyleBoxFlat.new();surface.bg_color=Color("203849");surface.border_color=Color("d3ac53");surface.set_border_width_all(2);surface.set_corner_radius_all(12)
		if state=="hover":surface.bg_color=Color("41616b")
		if state=="focus":surface.bg_color=Color.TRANSPARENT;surface.set_border_width_all(4)
		back_button.add_theme_stylebox_override(state,surface)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:back_button.add_theme_color_override(state,Color("fff3d3"))
	add_child(back_button);back_button.pressed.connect(return_from_settings)
	Progress.settings_changed.connect(sync_settings)
	Progress.save_status_changed.connect(sync_save_notice)
	Mega.save_status_changed.connect(sync_save_notice)
	sync_settings();sync_save_notice();volume_slider.value_changed.connect(func(value):Progress.set_setting("volume",value));volume_slider.grab_focus()
	call_deferred("settle_labels")

func text(value,rect,font_size):
	var label=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_override("font",Art.font);label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("203849"));add_child(label);label.position=rect.position;label.size=rect.size;label.set_meta("settings_rect",rect);return label

func settle_labels():
	if not is_inside_tree():return
	var tree=get_tree()
	for pass_index in range(2):
		await tree.process_frame
		if not is_inside_tree() or is_queued_for_deletion():return
		for child in get_children():
			if child.has_meta("settings_rect"):
				var rect: Rect2=child.get_meta("settings_rect");child.position=rect.position;child.size=rect.size

func sync_settings(_key="",_value=null):
	volume_slider.set_value_no_signal(Progress.settings.volume)
	volume_label.text=str(roundi(Progress.settings.volume*100))+"%"
	for key in toggles:
		var value=bool(Mega.prefs.calm if key=="calm" else Progress.settings[key])
		toggles[key].set_pressed_no_signal(value)
		toggles[key].text=LABELS[key]+": "+("On" if value else "Off")
	style_selector.select(0 if bool(Progress.settings.get("characters_3d",true)) else 1 if bool(Progress.settings.get("painted_characters",true)) else 2)

func select_character_style(index: int) -> void:
	# One visible choice controls the new renderer without discarding the source
	# paintings or the earlier articulated presentation.
	Progress.set_setting("characters_3d",index==0,false)
	if index!=0:Progress.set_setting("painted_characters",index==1,false)
	Progress.save_game()
	sync_settings()

func change_toggle(key,value):
	if key=="calm":Mega.prefs.calm=value;Mega.save();sync_settings()
	else:Progress.set_setting(key,value)

func sync_save_notice(_ok=true):
	var failed=not Progress.last_save_ok or not Mega.last_save_ok
	save_notice.text="Saving failed. Your adventure is still open. Use Back to try again." if failed else "Recovered your previous saved adventure." if Progress.recovered_backup or Mega.recovered_backup else "Preferences are shared by both adventures."
	save_notice.add_theme_color_override("font_color",Color("8b392b" if failed else "53665a"))

func return_from_settings():
	Progress.save_game();Mega.save()
	if done.is_valid():done.call()

func _unhandled_input(event):
	if event is InputEventKey and event.echo:return
	if event.is_action_pressed("ui_cancel") or (InputMap.has_action("pause") and event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled();return_from_settings()
