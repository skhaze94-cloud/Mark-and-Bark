extends Node

var index: Dictionary = {}
var cache: Dictionary = {}
var font: Font
var missing_assets: Array[String] = []

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/index.json"))
	if parsed is Dictionary:
		index = parsed
	font = load("res://assets/readable.ttf") if ResourceLoader.exists("res://assets/readable.ttf") else ThemeDB.fallback_font

func tex(id: String) -> Texture2D:
	if id=="young_actions_cheer":return tex("young_actions_jump")
	if cache.has(id):
		return cache[id]
	var texture: Texture2D
	if index.has(id) and ResourceLoader.exists(index[id].path):
		texture = load(index[id].path)
	if texture == null:
		if id not in missing_assets:
			missing_assets.append(id)
			push_warning("Missing artwork: " + id + ". Check assets/index.json and the bundled PNGs.")
		# Missing character poses must never quietly become an unrelated square.
		var fallback = "young_actions_idle" if id.begins_with("young_") else "bark_actions_idle" if id.begins_with("bark_") else ""
		if not fallback.is_empty() and fallback != id:
			return tex(fallback)
		var image = Image.create(64,64,false,Image.FORMAT_RGBA8)
		image.fill(Color("d3ae59"))
		texture = ImageTexture.create_from_image(image)
	cache[id] = texture
	return texture

func character(id: String, articulated: bool = true) -> Sprite2D:
	var s: Sprite2D = load("res://scripts/character_rig.gd").new() if articulated and (id.begins_with("young_") or id.begins_with("bark_")) else Sprite2D.new()
	s.texture = tex(id)
	s.centered = false
	s.offset = Vector2(-256,-612)
	return s

func game_actor(id: String) -> Sprite2D:
	var actor = character(id)
	actor.gameplay_actor = true
	return actor

func prop(id: String, size: float) -> Sprite2D:
	var s = Sprite2D.new()
	s.texture = tex(id)
	var dims = s.texture.get_size()
	s.centered = false
	var pivot = index.get(id,{}).get("pivot",[dims.x/2,dims.y])
	s.offset = -Vector2(float(pivot[0]),float(pivot[1]))
	s.scale = Vector2.ONE * size / maxf(dims.x,dims.y)
	return s
