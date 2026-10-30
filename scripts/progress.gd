extends Node

const SAVE_PATH = "user://big_idea_save.json"
const SETTING_DEFAULTS = {"volume":0.45, "reduced_motion":false, "touch":false, "music":true, "painted_characters":true, "characters_3d":true}
signal settings_changed(key: String, value: Variant)
signal save_status_changed(ok: bool)
var data: Dictionary = {}
var settings: Dictionary = SETTING_DEFAULTS.duplicate(true)
var tutorial_done: bool = false
var save_enabled: bool = true
var save_path: String = SAVE_PATH
var storage=preload("res://scripts/save_storage.gd").new()
var last_save_ok=true
var last_save_error: Error=OK
var recovered_backup=false

func _ready() -> void:
	reset_game(false)
	settings=SETTING_DEFAULTS.duplicate(true)
	tutorial_done=false;last_save_ok=true;last_save_error=OK
	load_save()

func reset_game(write: bool = true) -> void:
	data = {"shrunken":false, "stage":0, "notebook":false, "plant":false, "plant_restored":false, "books":false, "pencil":false, "assembled":0, "leaves":[], "bark_token":false, "discoveries":[], "checkpoint":220.0, "completed":false, "attempts":0}
	if write:
		save_game()

func save_game() -> bool:
	if not save_enabled:
		return true
	last_save_error=storage.write_atomic(save_path,{"version":1,"data":data,"settings":settings,"tutorial_done":tutorial_done},valid_document)
	last_save_ok=last_save_error==OK
	if last_save_ok:recovered_backup=false
	save_status_changed.emit(last_save_ok)
	return last_save_ok

func valid_document(document: Dictionary) -> bool:
	var version=document.get("version")
	return (version is int or version is float) and version==1 and document.get("data") is Dictionary

func read_valid(path: String) -> Dictionary:
	var document=storage.read_json(path)
	return document if valid_document(document) else {}

func set_setting(key: String, value: Variant, write: bool = true) -> bool:
	if not SETTING_DEFAULTS.has(key):return false
	if key=="volume":
		if not (value is int or value is float) or not is_finite(float(value)):return false
		value=clampf(float(value),0,1)
	elif not value is bool:return false
	if settings.get(key)==value:return true
	settings[key]=value
	settings_changed.emit(key,value)
	return save_game() if write else true

func finite_number(value: Variant, fallback: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):return float(value)
	return fallback

func unique_known(values: Array, allowed: Array) -> Array:
	var result: Array=[]
	for value in values:
		if value is String and value in allowed and not value in result:result.append(value)
	return result

func load_save() -> void:
	recovered_backup=false
	var parsed=read_valid(save_path)
	if parsed.is_empty():
		parsed=read_valid(save_path+".bak")
		recovered_backup=not parsed.is_empty()
	if parsed.is_empty():return
	var stored = parsed.get("data",{})
	if stored is Dictionary:
		for key in data:
			if stored.has(key) and typeof(stored[key]) == typeof(data[key]):
				data[key] = stored[key]
		# JSON numbers deserialize as floats. Validate integral fields explicitly.
		for key in ["stage","assembled","attempts"]:
			if stored.get(key) is float or stored.get(key) is int:
				data[key] = int(finite_number(stored[key],data[key]))
	data.stage = clampi(int(data.stage),0,7)
	data.assembled = clampi(int(data.assembled),0,3)
	data.checkpoint = clampf(finite_number(data.checkpoint,220),100.0,5400.0)
	data.attempts = clampi(int(data.attempts),0,999999)
	data.leaves = unique_known(data.leaves,["leaf_1","leaf_2","leaf_3","leaf_4","leaf_5","leaf_6"])
	data.discoveries = unique_known(data.discoveries,["doodle_1","doodle_2"])
	tutorial_done = parsed.get("tutorial_done",false) if parsed.get("tutorial_done") is bool else false
	var saved_settings=parsed.get("settings",{})
	for key in SETTING_DEFAULTS:
		var value=saved_settings.get(key) if saved_settings is Dictionary else null
		if key=="volume":value=clampf(finite_number(value,SETTING_DEFAULTS.volume),0,1)
		elif not value is bool:value=SETTING_DEFAULTS[key]
		set_setting(key,value,false)

func collect_leaf(id: String) -> bool:
	if id in data.leaves:
		return false
	data.leaves.append(id)
	save_game()
	return true

func set_checkpoint(x: float) -> void:
	data.checkpoint = clampf(x,100.0,5400.0)
	save_game()

func advance(to_stage: int) -> void:
	data.stage = maxi(int(data.stage),to_stage)
	save_game()
