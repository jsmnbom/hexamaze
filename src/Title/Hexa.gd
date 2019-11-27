extends MeshInstance2D

var size = Vector2(10,10)

func _ready():
	_on_resize()
	
func _on_resize():
	var st = SurfaceTool.new()
	var s = size
	position = size
	
#	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
#	st.add_uv(Vector2(0, 0))
#	st.add_color(Color(1,1,1))
#
#	st.add_vertex(Vector3(0,0,0))
#	for i in range(7):
#		var r = TAU / 6 * i
#		st.add_vertex(utils.sized_vec3_from_r(r, s))
#	st.add_vertex(Vector3(0,0,0))
	
	st.clear()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	for i in range(6):
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * i, s))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * (i+1), s))
			
	mesh = st.commit()