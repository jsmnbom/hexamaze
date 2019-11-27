extends Node2D

var size = Vector2(5,5)

func _ready():
	_on_resize()
	
func _on_resize():
	
	var viewport_size = get_viewport().size
	var viewport_min = min(viewport_size.x, viewport_size.y)
	size = viewport_min / 48
	
	var st = SurfaceTool.new()
	var s = size
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	st.add_vertex(Vector3(-s, -s, 0))
	st.add_vertex(Vector3(s, -s, 0))
	st.add_vertex(Vector3(-s, s, 0))
	
	st.add_vertex(Vector3(-s, s, 0))
	st.add_vertex(Vector3(s, -s, 0))
	st.add_vertex(Vector3(s, s, 0))
	
	$Mesh.mesh = st.commit()
	
	var points = PoolVector2Array()
	points.append(Vector2(-s, -s))
	points.append(Vector2(s, -s))
	points.append(Vector2(s, s))
	points.append(Vector2(-s, s))
		
	var shape = ConvexPolygonShape2D.new()
	shape.points = points
	$Area/Collision.shape = shape

func _on_Area_body_entered(_body):
	events.emit_signal('ability_pickup', self)
	
func del():
	$AnimationPlayer.stop()
	$Tween.interpolate_property(self, 'modulate:a', self.modulate.a, 0.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 1.0, 'queue_free')
	$Tween.start()
