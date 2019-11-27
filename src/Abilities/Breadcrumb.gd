extends MeshInstance2D

var size = 10
var i = 0

func _ready():
	pass # Replace with function body.

func _on_resize():
	var viewport_size = get_viewport().size
	var viewport_min = min(viewport_size.x, viewport_size.y)
	size = viewport_min / 24
	
	var st = SurfaceTool.new()
	var s = size
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	st.add_vertex(Vector3(0,0,0))
	st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * (i), s))
	st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * (i+1), s))
	
	mesh = st.commit()