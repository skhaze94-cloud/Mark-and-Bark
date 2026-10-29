extends CanvasLayer

var retry: Callable
var quit_anyway: Callable
var keep_button: Button
var retry_button: Button
var quit_button: Button
var was_paused=false
var chosen=false
var labels=[]

static func save_all() -> bool:
	var story_ok=Progress.save_game()
	var climbs_ok=Mega.save()
	return story_ok and climbs_ok

func _ready():
	name="SaveExit";layer=100;process_mode=Node.PROCESS_MODE_ALWAYS
	was_paused=get_tree().paused;get_tree().paused=true
	var root=Control.new();root.size=Vector2(1280,720);add_child(root)
	var veil=ColorRect.new();veil.size=Vector2(1280,720);veil.color=Color(.05,.10,.12,.76);root.add_child(veil)
	var panel=Panel.new();panel.position=Vector2(320,190);panel.size=Vector2(640,340)
	var style=StyleBoxFlat.new();style.bg_color=Color("f4ecd8");style.border_color=Color("d3ac53");style.set_border_width_all(3);style.set_corner_radius_all(18);panel.add_theme_stylebox_override("panel",style);root.add_child(panel)
	text(panel,"YOUR PROGRESS HASN'T BEEN SAVED",Rect2(30,27,580,45),25)
	text(panel,"Your adventure is still open. Try saving again, or keep playing and return later.",Rect2(30,102,580,85),22)
	retry_button=button(panel,"Try again",Rect2(30,245,175,57),func():choose(retry))
	keep_button=button(panel,"Keep playing",Rect2(225,245,190,57),func():choose(Callable()))
	quit_button=button(panel,"Quit anyway",Rect2(435,245,175,57),func():choose(quit_anyway))
	keep_button.grab_focus()
	call_deferred("settle_labels")

func text(parent,value,rect,font_size):
	var label=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_override("font",Art.font);label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("203849"));label.text=value;parent.add_child(label);label.position=rect.position;label.size=rect.size;label.set_meta("save_rect",rect);labels.append(label)

func settle_labels():
	if not is_inside_tree():return
	var tree=get_tree()
	for pass_index in range(2):
		await tree.process_frame
		if not is_inside_tree() or is_queued_for_deletion():return
		for label in labels:
			var rect: Rect2=label.get_meta("save_rect");label.position=rect.position;label.size=rect.size

func button(parent,value,rect,action):
	var control=Button.new();control.text=value;control.add_theme_font_override("font",Art.font);control.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","focus"]:
		var surface=StyleBoxFlat.new();surface.bg_color=Color("fff3d3");surface.border_color=Color("d3ac53");surface.set_border_width_all(2);surface.set_corner_radius_all(12)
		if state=="hover":surface.bg_color=Color("e9d49a")
		if state=="focus":surface.bg_color=Color.TRANSPARENT;surface.set_border_width_all(4)
		control.add_theme_stylebox_override(state,surface)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:control.add_theme_color_override(state,Color("203849"))
	parent.add_child(control);control.position=rect.position;control.size=rect.size;control.pressed.connect(action);return control

func choose(action: Callable):
	if chosen:return
	chosen=true;get_tree().paused=was_paused;queue_free()
	if action.is_valid():action.call_deferred()

func _exit_tree():
	if not chosen:get_tree().paused=was_paused

func _unhandled_input(event):
	if event is InputEventKey and event.echo:return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled();choose(Callable())
