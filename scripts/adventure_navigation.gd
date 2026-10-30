extends Node

const HOME="res://scenes/adventures.tscn"
const STORY="res://scenes/main.tscn"
const CLIMBS="res://scenes/mega.tscn"
const STUDIO="res://scenes/animation_studio.tscn"
var switching=false

func _ready() -> void:
	if OS.has_feature("android"):
		get_tree().quit_on_go_back=false

func _notification(what: int) -> void:
	if not OS.has_feature("android"):return
	if what==NOTIFICATION_APPLICATION_PAUSED:suspend_mobile()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:back_mobile()

func suspend_mobile() -> void:
	# Android can suspend without the desktop window-focus notification. Release
	# held fingers and keep the existing pause screen open when the app returns.
	var scene=get_tree().current_scene
	if is_instance_valid(scene):
		scene.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		if scene.scene_file_path==STUDIO and not scene.paused:scene.toggle_pause()
	preload("res://scripts/save_exit.gd").save_all()

func back_mobile() -> void:
	if switching or get_tree().paused:return
	var scene=get_tree().current_scene
	if not is_instance_valid(scene):return
	if scene.scene_file_path==HOME:
		if is_instance_valid(scene.settings_overlay):scene.close_settings()
		else:scene.request_quit()
	elif scene.scene_file_path==STUDIO:go(HOME)
	elif scene.scene_file_path in [STORY,CLIMBS]:
		if scene.mode=="title":go(HOME);return
		var event=InputEventAction.new();event.action="pause";event.pressed=true
		scene._unhandled_input(event)

func go(destination: String, action: String = "") -> void:
	if switching:return
	if destination not in [HOME,STORY,CLIMBS,STUDIO]:
		push_error("Unknown adventure destination: "+destination)
		return
	switching=true
	var previous=get_tree().current_scene
	if is_instance_valid(previous):
		if previous.has_method("drain_audio"):await previous.drain_audio()
		var soundscape=previous.get("soundscape")
		if is_instance_valid(soundscape):await soundscape.drain()
	var error=get_tree().change_scene_to_file(destination)
	if error!=OK:
		switching=false
		push_error("Unable to open adventure: "+destination)
		return
	await get_tree().process_frame
	while get_tree().current_scene==null:await get_tree().process_frame
	switching=false
	var next=get_tree().current_scene
	if not action.is_empty() and is_instance_valid(next) and next.has_method(action):
		next.call(action)
