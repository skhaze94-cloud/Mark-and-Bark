extends Node

const HOME="res://scenes/adventures.tscn"
const STORY="res://scenes/main.tscn"
const CLIMBS="res://scenes/mega.tscn"
const STUDIO="res://scenes/animation_studio.tscn"
var switching=false

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
