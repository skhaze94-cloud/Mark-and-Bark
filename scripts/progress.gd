extends Node

const SAVE_PATH = "user://big_idea_save.json"
var data: Dictionary = {}
var settings: Dictionary = {"volume":0.45, "reduced_motion":false, "touch":false, "music":true, "painted_characters":true}
var tutorial_done: bool = false
var save_enabled: bool = true

func _ready() -> void:
	reset_game(false)
	load_save()

func reset_game(write: bool = true) -> void:
	data = {"shrunken":false, "stage":0, "notebook":false, "plant":false, "plant_restored":false, "books":false, "pencil":false, "assembled":0, "leaves":[], "bark_token":false, "discoveries":[], "checkpoint":220.0, "completed":false, "attempts":0}
	if write:
		save_game()

func save_game() -> void:
	if not save_enabled:
		return
	var file = FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"version":1,"data":data,"settings":settings,"tutorial_done":tutorial_done}))
	file.close()
	DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)

func finite_number(value: Variant, fallback: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):return float(value)
	return fallback

func unique_known(values: Array, allowed: Array) -> Array:
	var result: Array=[]
	for value in values:
		if value is String and value in allowed and not value in result:result.append(value)
	return result

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or parsed.get("version",0) != 1:
		return
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
	var saved_settings = parsed.get("settings",{})
	if saved_settings is Dictionary:
		settings.volume = clampf(finite_number(saved_settings.get("volume"),0.45),0.0,1.0)
		for key in ["reduced_motion","touch","music","painted_characters"]:
			var value=saved_settings.get(key)
			if value is bool:settings[key]=value

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
