extends RefCounted

static func stream(id: String) -> AudioStreamWAV:
	var path="res://assets/"+id+".wav"
	if not ResourceLoader.exists(path):return null
	var source=load(path) as AudioStreamWAV
	if source==null:return null
	# Never depend on a different scene having modified the shared cached WAV.
	var loop=source.duplicate() as AudioStreamWAV
	loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin=0
	loop.loop_end=roundi(loop.get_length()*loop.mix_rate)
	return loop
