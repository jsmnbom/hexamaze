extends MeshInstance2D

var value = 0.0 setget _set_value
var size = Vector2()
var parts = 1

func _on_resize(progress_height):
	position += Vector2(0, get_viewport().size.y - progress_height)
	size = Vector2(get_viewport().size.x, progress_height)
	
	self.value = value
	
func _set_value(new_value):
	value = new_value
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	
	var s = Vector2(size.x / parts, size.y)
	
	for i in range(parts):
		st.add_color(Color.from_hsv(0, 0, 1.0-0.2*(i%2), 0.5))
		var start_x = s.x*i
		var x = s.x
		if start_x > value * size.x:
			break
		elif start_x + x > value*size.x:
			x = value*size.x - (start_x)
		
		st.add_vertex(Vector3(start_x, 0, 0))
		st.add_vertex(Vector3(start_x, s.y, 0))
		st.add_vertex(Vector3(start_x+x, 0, 0))
		st.add_vertex(Vector3(start_x+x, s.y, 0))
	
		st.add_index(0+i*4);
		st.add_index(1+i*4);
		st.add_index(2+i*4);
		
		st.add_index(1+i*4);
		st.add_index(2+i*4);
		st.add_index(3+i*4);
		
	mesh = st.commit()
	