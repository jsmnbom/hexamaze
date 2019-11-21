extends KinematicBody2D

var size

func _on_resize():
	var img_size = ceil(max(get_viewport().size.x, get_viewport().size.y) / 50)
	prints('Player.light.tex.size', img_size)
	var img = Image.new()
	img.create(img_size, img_size, false, 0)
	img.fill(Color(1,1,1))
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	$Light.texture = tex
	$Light.texture_scale = 50
	#$AmbientLight.texture = tex
	#$AmbientLight.texture_scale = 50
	
	prints('Player.size', size)
	
	var points = PoolVector2Array()
	for i in range(6):
		var r = TAU / 6 * i
		points.append(utils.sized_vec_from_r(r, size))
		
	var shape = ConvexPolygonShape2D.new()
	shape.points = points
	$Collision.shape = shape