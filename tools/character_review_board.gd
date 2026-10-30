extends SceneTree
## Assemble actual native renders; no generated concept art is substituted.
const DIR="res://test_output/character_showcase/"
const OUTPUT="res://test_output/"
class Board extends Node2D:
 var items=[]
 func _draw():
  draw_rect(Rect2(0,0,1280,720),Color("f5eddb"))
  for item in items:
   draw_texture_rect(item.texture,item.rect,false,Color(0,0,0,1) if item.silhouette else Color.WHITE)
 func title(value,at,size=22):
  var label=Label.new();label.text=value;label.position=at;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",Color("304a53"));add_child(label)
 func art(path,center,height,silhouette=false):
  var img=Image.load_from_file(ProjectSettings.globalize_path(path))
  if img==null:return
  var cropped=img.get_region(img.get_used_rect());var dims=Vector2(cropped.get_size())*height/cropped.get_height()
  items.append({"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(center-Vector2(dims.x*.5,dims.y),dims),"silhouette":silhouette})
func _initialize():call_deferred("run")
func save_board(board,name):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT+name))
 board.queue_free();await process_frame
func run():
 var board=Board.new();root.add_child(board)
 board.title("MARK & BARK · FULL OF CHARACTER",Vector2(34,14),28)
 for col in range(3):board.title(["Original concept paintings","4.1 · A Painting Come to Life","4.2 · Full of Character"][col],Vector2(col*426+32,57),20)
 for row in range(2):
  var role="mark" if row==0 else "bark";var y=365 if row==0 else 685
  board.title(role.to_upper(),Vector2(20,105+row*310),16)
  board.art("res://assets/"+("young_front.png" if row==0 else "bark_front.png"),Vector2(210,y),255)
  for col in [1,2]:board.art(DIR+("4.1" if col==1 else "4.2")+"_"+role+"_idle_front.png",Vector2(col*426+210,y),255)
 await save_board(board,"character42_comparison.png")
 board=Board.new();root.add_child(board);board.title("4.2 · FACES, SILHOUETTES & VIEWS",Vector2(30,12),28)
 var views=["front","quarter","front","quarter"]
 for col in range(4):
  var pose="idle" if col<2 else "delight"
  board.title(("Rest · " if col<2 else "Delight · ")+views[col],Vector2(col*320+45,58),20)
  for row in range(2):
   var role="mark" if row==0 else "bark";var y=340 if row==0 else 675
   var path=DIR+"4.2_"+role+"_"+pose+"_"+views[col]+".png"
   board.art(path,Vector2(col*320+125,y),225)
   board.art(path,Vector2(col*320+265,y),110,true)
 await save_board(board,"character42_studies.png")
 board=Board.new();root.add_child(board);board.title("4.2 · CURIOUS, UNSURE, SURPRISED, DELIGHTED & PROUD",Vector2(30,12),26)
 var poses=["curious","uncertain","surprise","delight","present"]
 for col in range(5):
  board.title(poses[col].capitalize(),Vector2(col*256+55,58),20)
  for row in range(2):
   var role="mark" if row==0 else "bark";var y=310 if row==0 else 630
   var path=DIR+"4.2_"+role+"_"+poses[col]+"_quarter.png"
   board.art(path,Vector2(col*256+128,y),215)
   board.art(path,Vector2(col*256+128,y+62),48)
 board.title("Native close views · small samples below show gameplay-size readability",Vector2(30,690),17)
 await save_board(board,"character42_poses.png")
 quit()
