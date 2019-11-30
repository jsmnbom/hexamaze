extends Control

onready var audio = get_node('/root/HexaMaze/Audio')

var size = 35

enum TYPE {WALL_WALK, LIGHT, BREADCRUMBS, WALL_LOOK, WALL_SHOW}
var mesh_instances = {}
onready var tween = $Tween

var type = null setget _set_type

var time_left = 0.0
var total_time = 0.0
var breadcrumbs_left = 0

func _ready():
	events.connect('ability_pickup', self, '_on_ability_pickup')

func _on_resize():
	rect_position -= Vector2($Label.rect_size.x, size*2+$Label.rect_size.y) + Vector2(10,10)
	$Label.rect_position = Vector2(0, size*2 + 10)
	
	rect_size = Vector2($Label.rect_size.x+5, size*2+20+$Label.rect_size.y)
	
	for mesh_instance in mesh_instances.values():
		mesh_instance.queue_free()
	
	for type_key in TYPE.keys():
		var type = TYPE[type_key]
		var mesh_instance = MeshInstance2D.new()
		mesh_instances[type] = mesh_instance
		
		match type:
			TYPE.WALL_WALK:
				mesh_instance.mesh = outline()
			TYPE.LIGHT:
				mesh_instance.mesh = light()
			TYPE.BREADCRUMBS:
				mesh_instance.mesh = dots(breadcrumbs_left)
			TYPE.WALL_LOOK:
				mesh_instance.mesh = cone()
			TYPE.WALL_SHOW:
				mesh_instance.mesh = walls()
		mesh_instance.hide()
		mesh_instance.position = Vector2($Label.rect_size.x/2, size)
		add_child(mesh_instance)
	
	if type != null:
		mesh_instances[type].show()
	
	$ProgressBar.position = -rect_global_position
	$ProgressBar._on_resize($Label.rect_size.y)
	audio._on_resize($Label.rect_size.y)

func _set_type(new_type):
	if new_type == null and type != null:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		tween.interpolate_property(mesh_instances[type], 'modulate:a', 1.0, 0.0, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.interpolate_property($Label, 'modulate:a', $Label.modulate.a, 0.0, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		type = null
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if type in mesh_instances:
			mesh_instances[type].hide()
		type = new_type
		mesh_instances[type].show()
		
		tween.interpolate_property(mesh_instances[type], 'modulate:a', 0.0, 1.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		tween.interpolate_property(mesh_instances[type], 'scale', Vector2(2,2), Vector2(1,1), 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		tween.interpolate_property($Label, 'modulate:a', $Label.modulate.a, 1.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		tween.start()
		
		match type:
			TYPE.WALL_WALK:
				total_time = 8.0
				breadcrumbs_left = 0
			TYPE.LIGHT:
				total_time = 8.0
				breadcrumbs_left = 0
			TYPE.BREADCRUMBS:
				total_time = 0.0
				breadcrumbs_left = 6
				mesh_instances[type].mesh = dots(breadcrumbs_left)
			TYPE.WALL_LOOK:
				total_time = 8.0
				breadcrumbs_left = 0
			TYPE.WALL_SHOW:
				total_time = 8.0
				breadcrumbs_left = 0
		time_left = total_time

func dots(count):
	var st = SurfaceTool.new()
	var s = size
	
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	st.add_vertex(Vector3(0,0,0))
	for i in range(count+1):
		var r = TAU / 6 * i
		st.add_vertex(utils.sized_vec3_from_r(r, s))
	st.add_vertex(Vector3(0,0,0))
	
	var mesh = st.commit()
	st.clear()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(0.5,0.5,0.5))
	
	for i in range(6):
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s))
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i+1, s))
		
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s))
		st.add_vertex(Vector3(0,0,0))
			
	return st.commit(mesh)

func cone():
	var st = SurfaceTool.new()
	var s = size
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.25, s))
	st.add_color(Color(0.1,0.1,0.1))
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.65, s))
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.85, s))
	
	var mesh = st.commit()
	st.clear()
	st.begin(Mesh.PRIMITIVE_LINE_LOOP)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.25, s))
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.65, s))
	st.add_vertex(utils.sized_vec3_from_r(TAU * 0.85, s))
	
	return st.commit(mesh)

func walls():
	var st = SurfaceTool.new()
	var s = size / 2.3
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_uv(Vector2(0, 0))
		
	for pos in [
		Vector3(0,0,0),
		Vector3((3.0/4.0)*2.0, 0.9, 0), Vector3((3.0/4.0)*2.0, -0.9, 0),
		Vector3(-(3.0/4.0)*2.0, 0.9, 0), Vector3(-(3.0/4.0)*2.0, -0.9, 0),
		Vector3(0, 1.8, 0), Vector3(0, -1.8, 0)
	]:
		st.add_color(Color(1,1,1))
		for i in range(6):
			st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s)+pos*s)
			st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i+1, s)+pos*s)
			
	return st.commit()

func light():
	var st = SurfaceTool.new()
	var s = size / 2.0
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	st.add_vertex(Vector3(0,0,0))
	for i in range(129):
		var r = TAU / 128 * i
		st.add_vertex(utils.sized_vec3_from_r(r, s))
	st.add_vertex(Vector3(0,0,0))
	
	var mesh = st.commit()
	st.clear()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_uv(Vector2(0, 0))
	st.add_color(Color(1,1,1))
	for i in range(7):
		var r = TAU / 6 * i
		st.add_vertex(utils.sized_vec3_from_r(r, s*1.8))
		st.add_vertex(utils.sized_vec3_from_r(r, s*3.0))
	
	return st.commit(mesh)

func outline():
	var st = SurfaceTool.new()
	var s = size * 1.1
	var s2 = size * 0.85
	
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_uv(Vector2(0, 0))
	
	st.add_color(Color(1,1,1))
	
	for i in range(6):
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s))
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s2))

	for i in range(6):
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s2))
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i+1, s2))
		
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i, s))
		st.add_vertex(utils.sized_vec3_from_r(TAU / 6 * i+1, s))

	return st.commit()

func _mouse_entered():
	if type != null:
		mesh_instances[type].scale = Vector2(1.2,1.2)
		$Label.add_color_override("font_color", Color(0,0,0))
		$Label.get_font("font").outline_size = 1
		$Label.get_font("font").outline_color = Color(1,1,1)

func _mouse_exited():
	if type != null:
		mesh_instances[type].scale = Vector2(1,1)
		$Label.add_color_override("font_color", Color(1,1,1))
		$Label.get_font("font").outline_size = 0

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed and type != null:
		activate_ability()
	if event is InputEventScreenTouch and not event.pressed and type != null:
		activate_ability()
	get_tree().set_input_as_handled()

func _unhandled_input(event):
	if event.is_action_released('ability') and type != null:
		activate_ability()

func activate_ability():
	audio.play_activate()
	if type == TYPE.BREADCRUMBS:
		$ProgressBar.parts = 6
		breadcrumbs_left -= 1
		$ProgressBar.value = float(breadcrumbs_left) / 6
		mesh_instances[type].mesh = dots(breadcrumbs_left)
		events.emit_signal('ability', {'type': type, 'i': breadcrumbs_left})
		if breadcrumbs_left == 0:
			$ProgressBar.hide()
			self.type = null
		$ProgressBar.show()
	elif time_left == total_time:
		$ProgressBar.parts = 1
		$ProgressBar.value = 1.0
		$Timer.wait_time = 0.1
		$Timer.start()
		events.emit_signal('ability', {'type': type, 'activated': true})
		tween.interpolate_property($Label, 'modulate:a', 1.0, 0.0, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		$ProgressBar.show()
		audio.start_ticking()

func _on_ability_pickup(map_ability):
	if type == null:
		audio.play_pickup()
		map_ability.del()
		self.type = utils.rng_choose(TYPE.values())

func _on_Timer_timeout():
	time_left -= 0.1
	$ProgressBar.value = time_left / total_time
	if time_left <= 0:
		$Timer.stop()
		$ProgressBar.hide()
		events.emit_signal('ability', {'type': type, 'activated': false})
		self.type = null
		audio.stop_ticking()
		
	
