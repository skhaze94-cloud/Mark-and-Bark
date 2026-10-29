extends Node
const PATH="user://mark_bark_mega.json"
const LIMITS=[23,26,32]
signal save_status_changed(ok: bool)
var enabled=true
var unlocked=1
var current=0
var intro_done=false
var runs: Array=[]
var best: Array=[]
var prefs={"calm":false}
var last_save_ok=true
var recovered_backup=false
var save_path: String=PATH
var storage=preload("res://scripts/save_storage.gd").new()
var last_save_error: Error=OK
func _ready():
	reset(false);prefs={"calm":false};recovered_backup=false
	last_save_ok=true;last_save_error=OK
	var data=read_valid(save_path)
	if data.is_empty():
		data=read_valid(save_path+".bak");recovered_backup=not data.is_empty()
	if data.is_empty():return
	unlocked=clampi(number(data.get("unlocked"),1),1,3)
	current=clampi(number(data.get("current"),0),0,unlocked-1)
	intro_done=truth(data.get("intro_done",false))
	if data.get("prefs") is Dictionary:prefs.calm=truth(data.prefs.get("calm",false))
	for i in range(3):
		if data.get("runs") is Array and data.runs.size()>i and data.runs[i] is Dictionary:
			var r=data.runs[i]
			runs[i].checkpoint=clampi(number(r.get("checkpoint"),-1),-1,LIMITS[i])
			runs[i].quest=truth(r.get("quest",false));runs[i].token=truth(r.get("token",false))
			for id in r.get("leaves",[]) if r.get("leaves") is Array else []:
				if (id is int or id is float) and is_finite(float(id)) and int(id) in range(24) and not int(id) in runs[i].leaves:runs[i].leaves.append(int(id))
		if data.get("best") is Array and data.best.size()>i and data.best[i] is Dictionary:
			best[i].complete=truth(data.best[i].get("complete",false))
			best[i].leaves=clampi(number(data.best[i].get("leaves"),0),0,24)
			best[i].token=truth(data.best[i].get("token",false))
func read_valid(path):
	var d=storage.read_json(path)
	return d if valid_document(d) else {}
func valid_document(d: Dictionary) -> bool:
	var version=d.get("version")
	return (version is int or version is float) and (version==1 or version==2)
func reset(write=true):
	unlocked=1;current=0;intro_done=false;runs=[];best=[]
	for i in range(3):
		runs.append({"checkpoint":-1,"quest":false,"leaves":[],"token":false})
		best.append({"complete":false,"leaves":0,"token":false})
	if write:save()
func replay(i):
	runs[i]={"checkpoint":-1,"quest":false,"leaves":[],"token":false};current=i;save()
func finish():
	best[current].complete=true
	best[current].leaves=maxi(best[current].leaves,runs[current].leaves.size())
	best[current].token=best[current].token or runs[current].token
	unlocked=mini(3,maxi(unlocked,current+2));save()
func sync_best():
	for i in range(3):
		if best[i].complete:
			best[i].leaves=maxi(best[i].leaves,runs[i].leaves.size())
			best[i].token=best[i].token or runs[i].token
func save():
	sync_best()
	if not enabled:return true
	last_save_error=storage.write_atomic(save_path,{"version":2,"unlocked":unlocked,"current":current,"intro_done":intro_done,"runs":runs,"best":best,"prefs":prefs},valid_document)
	last_save_ok=last_save_error==OK
	if last_save_ok:recovered_backup=false
	save_status_changed.emit(last_save_ok)
	return last_save_ok
func number(value,fallback):
	if (value is int or value is float) and is_finite(float(value)):return int(value)
	return fallback

func truth(value):return value is bool and value
