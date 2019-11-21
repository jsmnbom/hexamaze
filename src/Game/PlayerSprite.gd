extends MeshInstance2D

func _ready():
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize()

func _on_resize():
	var viewport_size = get_tree().root.size
	var viewport_min = min(viewport_size.x, viewport_size.y)
	var size = viewport_min / 65
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color.from_hsv(0.25, 1, 1))
	
	st.add_vertex(Vector3(0,0,0))
	for i in range(7):
		var r = TAU / 6 * i
		st.add_vertex(utils.sized_vec3_from_r(r, size))
	st.add_vertex(Vector3(0,0,0))
		
	mesh = st.commit()