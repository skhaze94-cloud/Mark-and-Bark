extends Node2D
var game
var running=false
var age=0.0
var beam=0.0
var done: Callable
var layer: CanvasLayer
var caption: Label
var heading: Label
var restoring=false
func _ready():
	z_index=2
	layer=CanvasLayer.new();layer.layer=11;add_child(layer);layer.hide()
	var root=Control.new();layer.add_child(root)
	game.card(root,Rect2(20,16,1240,75),"203849")
	heading=game.text(root,"A SMALL ACCIDENT · BIG POSSIBILITIES",Rect2(45,34,920,42),25,"fff3d3")
	game.button(root,"Skip intro",Rect2(1040,28,200,50),finish)
	var panel=game.card(root,Rect2(20,605,1240,95),"203849")
	caption=game.text(panel,"",Rect2(25,15,1190,70),22,"fff3d3")
func begin(callback,restore=false):
	restoring=restore
	heading.text="THE BIG IDEA · BACK TO OURSELVES" if restore else "A SMALL ACCIDENT · BIG POSSIBILITIES"
	game.close();game.mode="ray";game.busy=true;game.player.suspended=true;game.player.enabled=false;game.hud.hide()
	game.player.position=Vector2(580,645);game.player.velocity=Vector2.ZERO;game.camera.position=Vector2(800,450)
	game.campus.bark.position=Vector2(745,645);game.campus.bark.texture=Art.tex("bark_actions_point")
	done=callback;age=0;running=true;layer.show();update_story()
func _physics_process(delta):
	if not running:return
	age+=delta
	if age>9:finish()
	else:update_story()
func update_story():
	var ratio=clampf((age-2.5)/2.7,0,1)
	if Progress.settings.reduced_motion:ratio=1.0 if age>4 else 0.0
	var ease=ratio*ratio*(3-2*ratio)
	game.player.visual_scale=lerpf(.24,.42,ease) if restoring else lerpf(.42,.24,ease);game.player.sprite.scale=Vector2.ONE*game.player.visual_scale;game.player.sprite.texture=Art.tex("young_actions_idle");game.player.ghost.hide()
	game.campus.bark.scale=Vector2.ONE*(lerpf(.20,.35,ease) if restoring else lerpf(.35,.20,ease))
	beam=.18 if age>2.5 and age<5.2 else 0.0
	caption.text="Mark: 'The ray says make your ideas smaller.'   Bark: 'Press it twice! Twice as helpful!'" if age<2.5 else "Mark: 'Bark! That's the SHRINK dial!'   Bark: 'A very small misunderstanding.'" if age<5.2 else "Mark: 'The bookcase is a mountain!'   Bark: 'Then jump onto my leaves. We'll climb together!'"
	if restoring:
		caption.text="Mark: 'The design, power cell and lens. Let's try a better setting.'" if age<2.5 else "Mark: 'It worked!'   Bark: 'Of course. We only found twelve ways it didn't.'" if age<5.2 else "Mark: 'Three.'   Bark: 'I counted the ones before you arrived. Now put those books back!'"
	queue_redraw()
func _draw():
	if not running:return
	var s=StyleBoxFlat.new();s.bg_color=Color("63816d");s.border_color=Color("203849");s.set_border_width_all(3);s.set_corner_radius_all(12)
	draw_style_box(s,Rect2(900,455,130,75));draw_rect(Rect2(915,470,93,12),Color("e4c275"));draw_circle(Vector2(962,505),14,Color("203849"));draw_line(Vector2(962,505),Vector2(971,496),Color("f5deb0"),3)
	draw_line(Vector2(900,479),Vector2(853,481),Color("be9650"),20);draw_circle(Vector2(850,481),17,Color("203849"));draw_circle(Vector2(850,481),11,Color("e5c875"))
	for x in [915,1015]:draw_line(Vector2(x,530),Vector2(x,650),Color("203849"),8)
	if beam>0:draw_colored_polygon(PackedVector2Array([Vector2(850,481),Vector2(485,335),Vector2(485,648)]),Color(1,.88,.48,beam))
func finish():
	if not running:return
	running=false;beam=0;layer.hide();queue_redraw();game.player.visual_scale=.24;game.player.sprite.scale=Vector2.ONE*.24;game.campus.bark.scale=Vector2.ONE*.20;game.mode="campus";game.close();game.hud.show()
	if done.is_valid():done.call()
