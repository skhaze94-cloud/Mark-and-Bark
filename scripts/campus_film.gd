extends Node
const SHOTS = [
	{"room":1,"x":2600.0,"camera":2700.0,"title":"THE QUIET GARDEN","caption":"Every big idea begins with a small question.","pose":"young_actions_notebook"},
	{"room":0,"x":800.0,"camera":850.0,"title":"BIG IDEAS DAY","caption":"Today, the school is full of possibilities.","pose":"young_actions_idle"},
	{"room":2,"x":4510.0,"camera":4650.0,"title":"THE INVENTION WORKSHOP","caption":"Somewhere between a notebook and a puff of wind…","pose":"young_actions_paper_plane"},
	{"room":1,"x":2640.0,"camera":2700.0,"title":"MARK & BARK: THE BIG IDEA","caption":"A first attempt. A better idea. A friend.","pose":"young_actions_idle"}
]
var game
var age: float = 0.0
var running: bool = false
var shot_index: int = -1
var done: Callable
var root: Control
var title: Label
var caption: Label
var veil: ColorRect
var skip_button: Button
var plane: Sprite2D
var staged: Array[Node] = []

func _ready() -> void:
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	root.hide()
	game.hud.get_parent().add_child(root)
	veil=ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color=Color("142b34")
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)
	for rect in [Rect2(0,0,1280,65),Rect2(0,619,1280,101)]:
		var bar=ColorRect.new()
		bar.position=rect.position
		bar.size=rect.size
		bar.color=Color("142b34")
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
	game.label_at(root,"A LITTLE FILM ABOUT A BIG IDEA",Rect2(28,18,750,35),18,"dec888")
	title=game.label_at(root,"",Rect2(70,628,1140,40),26,"f6e4b3")
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption=game.label_at(root,"",Rect2(70,673,1140,35),20,"e4eddf")
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	skip_button=game.button(root,"Skip film  [E]",Rect2(1040,9,214,46),finish)

func begin(callback: Callable) -> void:
	game.cancel_room_transition()
	game.close_modal()
	game.flight.clear()
	game.prediction.clear_points()
	game.mode="cinematic"
	game.busy=true
	game.hud.hide()
	game.player.enabled=false
	game.player.axis=0
	game.player.velocity=Vector2.ZERO
	game.player.right_bound=5600
	game.campus.build(false)
	age=0.0
	shot_index=-1
	done=callback
	running=true
	# Cosmetic imagined invention, never a quest mutation.
	for spec in [["collectibles_books",Vector2(4390,457),110],["collectibles_pencil",Vector2(4470,445),90],["collectibles_paper_plane",Vector2(4450,415),100]]:
		staged.append(game.campus.decorate(spec[0],spec[1],spec[2]))
	plane=Art.prop("collectibles_paper_plane",85)
	plane.z_index=9
	game.campus.add_child(plane)
	skip_button.text="Skip film" if game.input_touch or Progress.settings.touch or OS.has_feature("mobile") else "Skip film  [E]"
	root.show()
	update_shot()

func _physics_process(delta: float) -> void:
	if not running:return
	age+=delta
	if age>=28.0:
		finish()
		return
	update_shot()

func update_shot() -> void:
	var next_shot=mini(3,int(age/7.0))
	var shot: Dictionary=SHOTS[next_shot]
	var phase=fmod(age,7.0)/7.0
	if next_shot!=shot_index:
		shot_index=next_shot
		game.campus.enter_room(shot.room)
		game.player.position=Vector2(shot.x,610)
		game.player.velocity=Vector2.ZERO
		game.player.facing=1
		game.player.show_pose(shot.pose,8)
		game.campus.bark.position=Vector2(shot.x-115,610)
		game.campus.bark.texture=Art.tex("bark_actions_hint" if next_shot==0 else "bark_actions_point" if next_shot==1 else "bark_actions_cheer")
		game.campus.bark.scale=Vector2.ONE*0.26
		game.ambient.color=Color("f0eddf") if shot.room==1 else Color("e5e6e8") if shot.room==0 else Color("eee4d5")
		title.text=shot.title
		caption.text=shot.caption
	var reduced=bool(Progress.settings.reduced_motion)
	var ease=phase*phase*(3.0-2.0*phase)
	var drift=0.0 if reduced else lerpf(-95.0,95.0,ease)
	game.camera.position=Vector2(shot.camera+drift,395)
	game.camera.zoom=Vector2.ONE*(1.0 if reduced else 1.035+ease*0.025)
	game.campus.depth.camera_x=game.camera.position.x
	game.campus.foreground.camera_x=game.camera.position.x
	game.campus.scenery.camera_x=game.camera.position.x
	game.campus.reduced_motion=reduced
	game.player.reduced_motion=reduced
	veil.modulate.a=maxf(clampf(1-phase*7/0.6,0,1),clampf((phase*7-6.4)/0.6,0,1))*0.75
	if is_instance_valid(plane):
		plane.visible=next_shot==2 or next_shot==3
		plane.position=Vector2(shot.camera-360+ease*560,330-(0 if reduced else sin(phase*PI)*75))
		plane.rotation=0.0 if reduced else -0.11+ease*0.15
		if reduced:plane.position=Vector2(shot.camera+240,330)

func finish() -> void:
	if not running:return
	running=false
	root.hide()
	game.camera.zoom=Vector2.ONE
	game.player.pose_lock=0
	game.player.sprite.scale=Vector2(0.31*game.player.facing,0.31)
	game.busy=false
	for item in staged:
		if is_instance_valid(item):item.queue_free()
	staged.clear()
	if is_instance_valid(plane):plane.queue_free()
	var callback=done
	done=Callable()
	if callback.is_valid():callback.call()
