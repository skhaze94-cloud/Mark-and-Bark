extends Node
const PATH="user://mark_bark_mega.json"
var enabled=true
var unlocked=1
var current=0
var intro_done=false
var runs: Array=[]
var best: Array=[]
func _ready():
	reset(false)
	if FileAccess.file_exists(PATH):
		var d=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary and d.get("version")==1:
			unlocked=clampi(number(d.get("unlocked"),1),1,3)
			current=clampi(number(d.get("current"),0),0,unlocked-1)
			intro_done=d.get("intro_done",false)==true
			for i in range(3):
				if d.get("runs") is Array and d.runs.size()>i and d.runs[i] is Dictionary:
					var r=d.runs[i]
					runs[i].checkpoint=clampi(number(r.get("checkpoint"),-1),-1,[7,8,10][i])
					runs[i].quest=r.get("quest",false)==true
					runs[i].token=r.get("token",false)==true
					for id in r.get("leaves",[]) if r.get("leaves") is Array else []:
						if id is int or id is float:
							if int(id) in range(8) and not int(id) in runs[i].leaves:runs[i].leaves.append(int(id))
				if d.get("best") is Array and d.best.size()>i and d.best[i] is Dictionary:
					best[i].complete=d.best[i].get("complete",false)==true
					best[i].leaves=clampi(number(d.best[i].get("leaves"),0),0,8)
					best[i].token=d.best[i].get("token",false)==true
func reset(write=true):
	unlocked=1;current=0;intro_done=false
	runs=[];best=[]
	for i in range(3):
		runs.append({"checkpoint":-1,"quest":false,"leaves":[],"token":false})
		best.append({"complete":false,"leaves":0,"token":false})
	if write:save()
func replay(i):
	runs[i]={"checkpoint":-1,"quest":false,"leaves":[],"token":false}
	current=i;save()
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
	if not enabled:return
	var f=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version":1,"unlocked":unlocked,"current":current,"intro_done":intro_done,"runs":runs,"best":best}));f.close()
		DirAccess.rename_absolute(PATH+".tmp",PATH)

func number(value, fallback):
	if (value is int or value is float) and is_finite(float(value)):return int(value)
	return fallback
