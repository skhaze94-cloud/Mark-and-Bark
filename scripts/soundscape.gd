extends Node

var game
var music: AudioStreamPlayer
var garden: AudioStreamPlayer
var garden_gain: float = 0.0
var stopped: bool = false

func _ready() -> void:
	music=make_loop("campus_music")
	garden=make_loop("garden_ambience")

func make_loop(id: String) -> AudioStreamPlayer:
	var player=AudioStreamPlayer.new()
	add_child(player)
	var path="res://assets/"+id+".wav"
	if ResourceLoader.exists(path):
		var stream=load(path) as AudioStreamWAV
		if stream:
			stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin=0
			stream.loop_end=int(stream.get_length()*stream.mix_rate)
			player.stream=stream
			player.volume_db=-80
			player.play()
	return player

func _process(delta: float) -> void:
	if stopped:return
	var master: float=clampf(float(Progress.settings.volume),0,1)
	var quiet=game.busy and game.mode in ["tutorial","campus"]
	var enabled=bool(Progress.settings.get("music",true))
	music.stream_paused=quiet or not enabled or master<=0
	music.volume_db=linear_to_db(maxf(0.0001,master*0.34))
	var outside=game.campus.tutorial or game.campus.room==1
	garden_gain=move_toward(garden_gain,1.0 if outside else 0.0,delta*1.8)
	garden.stream_paused=quiet or master<=0
	garden.volume_db=linear_to_db(maxf(0.0001,master*garden_gain*0.18))

func shutdown() -> void:
	stopped=true
	for player in [music,garden]:
		if is_instance_valid(player):
			player.stream_paused=false
			player.stop()
			player.stream=null

func _exit_tree() -> void:
	shutdown()


func drain() -> void:
	shutdown()
	# AudioServer releases faded voices asynchronously. Use real wall time so
	# accelerated headless tests also give the mixer time to release them.
	var deadline=Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
