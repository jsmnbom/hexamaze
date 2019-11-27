extends Node2D

var MapAbility = preload('res://src/Abilities/MapAbility.tscn')
var Breadcrumb = preload('res://src/Abilities/Breadcrumb.tscn')

const layout = [3.0 / 2.0, 0.0, sqrt(3.0) / 2.0, sqrt(3.0)]
const layout_inv = [2.0 / 3.0, 0.0, -1.0 / 3.0, sqrt(3.0) / 3.0]

var size = Vector2(1, 1)
var origin = Vector2(0, 0)

var map_radius = 1
var map_hex_size

var map = {}
var maze_gen = MazeGen.new()
var goal_hex

onready var wall_body = $WallBody
onready var outer_wall_body = $OuterWallBody
var collision_shape_owner
var outer_collision_shape_owner

var light_occluders = {}
var enabled_light_occluder_hexes = []

var vp_top_left = Vector2()

var goal_position
var goal_distance_size

var map_abilities = []
var breadcrumbs = []

func _ready():
	collision_shape_owner = wall_body.create_shape_owner(self)
	outer_collision_shape_owner = outer_wall_body.create_shape_owner(self)

func _physics_process(_delta):
	var top_left_hex = pixel_to_hex(vp_top_left)
	
	var visible = []
	
	for hex in enabled_light_occluder_hexes:
		if not hex in visible:
			for occ in light_occluders[hex]:
				VisualServer.canvas_light_occluder_set_enabled(occ[0], false)
			enabled_light_occluder_hexes.erase(hex)
	
	for q in range(-1, map_hex_size.x+2):
		var q_offset = floor(float(q)/2.0)
		for r in range(-q_offset-1,  map_hex_size.y -q_offset +2):
			var hex = Vector3(q, r, -q-r) + top_left_hex
			if hex in light_occluders:
				visible.append(hex)
				if not hex in enabled_light_occluder_hexes:
					for occ in light_occluders[hex]:
						VisualServer.canvas_light_occluder_set_enabled(occ[0], true)
					enabled_light_occluder_hexes.append(hex)

func _on_resize():
	var viewport_size = get_viewport().size
	var viewport_min = min(viewport_size.x, viewport_size.y)
	var new_size = Vector2(viewport_min, viewport_min) / 8
	var size_diff = new_size / size
	size = new_size
	
	map_hex_size = viewport_size / Vector2(size.x/(3.0/4.0), size.y*2.0)
	
	_commit_walls()
	_calculate_light_occluders()
	if goal_hex:
		_commit_goal()
		_calculate_goal_distance_size()
	_commit_abilities()
	_commit_breadcrumbs(size_diff)
	
	return size_diff
	
		
func _calculate_goal_distance_size():
	goal_position = hex_to_pixel(goal_hex)
	
	var sizes = [
		hex_to_pixel(Vector3(-map_radius, 0, map_radius)).distance_to(goal_position),
		hex_to_pixel(Vector3(map_radius, 0, -map_radius)).distance_to(goal_position),
		hex_to_pixel(Vector3(0, -map_radius, map_radius)).distance_to(goal_position),
		hex_to_pixel(Vector3(0, map_radius, -map_radius)).distance_to(goal_position),
		hex_to_pixel(Vector3(map_radius, -map_radius, 0)).distance_to(goal_position),
		hex_to_pixel(Vector3(-map_radius, map_radius, 0)).distance_to(goal_position)
	]
	sizes.sort()
	goal_distance_size = sizes[-1]

func generate(_map_radius):
	map_radius = _map_radius
	var result = maze_gen.generate(map_radius)
	goal_hex = result[0]
	map = result[1]
	
	for ref in breadcrumbs:
		var breadcrumb = ref.get_ref()
		if breadcrumb:
			breadcrumb.queue_free()
	breadcrumbs = []
	
	_commit_walls()
	_commit_goal()
	_calculate_light_occluders()
	_calculate_goal_distance_size()
	
	_add_abilities()
	_commit_abilities()

func add_breadcrumb(pos, i):
	var breadcrumb = Breadcrumb.instance()
	breadcrumb.position = pos
	breadcrumb.i = i
	breadcrumbs.append(weakref(breadcrumb))
	add_child(breadcrumb)
	breadcrumb._on_resize()
	
func _commit_breadcrumbs(size_diff):
	for ref in breadcrumbs:
		var breadcrumb = ref.get_ref()
		if breadcrumb:
			breadcrumb.position *= size_diff
			breadcrumb._on_resize()

func _add_abilities():
	for data in map_abilities:
		var map_ability = data[1].get_ref()
		if map_ability:
			map_ability.queue_free()
	map_abilities = []
	
	var possible_hexes = map.keys().duplicate()
	possible_hexes.erase(goal_hex)
	possible_hexes.erase(Vector3(0,0,0))
	
	var hexes = utils.rng_sample((map.size()-8)*0.1, possible_hexes)
	for hex in hexes:
		var map_ability = MapAbility.instance()
		map_abilities.append([hex, weakref(map_ability)])
		add_child(map_ability)

func _commit_abilities():
	for data in map_abilities:
		var map_ability = data[1].get_ref()
		if map_ability:
			map_ability.position = hex_to_pixel(data[0])
			map_ability._on_resize()

func _calculate_light_occluders():
	for hex in light_occluders:
		for occ in light_occluders[hex]:
			VisualServer.free_rid(occ[0])
			VisualServer.free_rid(occ[1])
	light_occluders = {}
	enabled_light_occluder_hexes = []
	
	for hex in map:
		var center = hex_to_pixel(hex)
		
		var occs = []
		
		for i in range(6):
			if map[hex][i] and not _should_draw(hex, i):
				var from = TAU / 6 * i
				var to = TAU / 6 * (i+1)
				
				var polygon = PoolVector2Array()
				polygon.append(utils.sized_vec_from_r(from, size))
				polygon.append(utils.sized_vec_from_r(to, size))
				
				var p_occ = VisualServer.canvas_occluder_polygon_create()
				VisualServer.canvas_occluder_polygon_set_shape(p_occ, polygon, false)
				
				var occ = VisualServer.canvas_light_occluder_create()
				VisualServer.canvas_light_occluder_set_light_mask(occ, 1)
				VisualServer.canvas_light_occluder_attach_to_canvas(occ, get_canvas())
				VisualServer.canvas_light_occluder_set_enabled(occ, false)
				VisualServer.canvas_light_occluder_set_transform(occ, Transform2D(0, center))
				VisualServer.canvas_light_occluder_set_polygon(occ, p_occ)
				
				occs.append([occ, p_occ])
				
		light_occluders[hex] = occs

func _commit_walls():
	outer_wall_body.shape_owner_clear_shapes(outer_collision_shape_owner)
	wall_body.shape_owner_clear_shapes(collision_shape_owner)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_color(Color(1, 1, 1))
	st.add_uv(Vector2(0, 0))
	
	for hex in map:
		var center = hex_to_pixel(hex)
		var center3 = Vector3(center.x, center.y, 0)
		
		var edges = [false, false, false, false, false, false]
		if hex.x == map_radius:
			edges[0] = true
			edges[5] = true
		elif hex.x == -map_radius:
			edges[2] = true
			edges[3] = true
		
		if hex.y == map_radius:
			edges[1] = true
			edges[2] = true
		elif hex.y == -map_radius:
			edges[4] = true
			edges[5] = true
			
		if hex.z == map_radius:
			edges[3] = true
			edges[4] = true
		elif hex.z == -map_radius:
			edges[0] = true
			edges[1] = true
		
		for i in range(6):
			if map[hex][i] and not _should_draw(hex, i):
				var from = TAU / 6 * i
				var to = TAU / 6 * (i+1)
				st.add_vertex(utils.sized_vec3_from_r_vec2(from, size)+center3)
				st.add_vertex(utils.sized_vec3_from_r_vec2(to, size)+center3)
				
				if not edges[i]:
					var shape = SegmentShape2D.new()
					shape.a = utils.sized_vec_from_r(from, size) + center
					shape.b = utils.sized_vec_from_r(to, size) + center
					
					wall_body.shape_owner_add_shape(collision_shape_owner, shape)
					
			if edges[i]:
				var from = TAU / 6 * i
				var to = TAU / 6 * (i+1)
				
				var shape = SegmentShape2D.new()
				shape.a = utils.sized_vec_from_r(from, size) + center
				shape.b = utils.sized_vec_from_r(to, size) + center
				
				outer_wall_body.shape_owner_add_shape(outer_collision_shape_owner, shape)
		
	var wall_mesh = st.commit()
	$WallMesh.mesh = wall_mesh


func _commit_goal():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	
	for i in range(9,3,-1):
		st.add_color(Color(0,0,0, 0.15))
		
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 0, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 1, size*((float(i)/10))))
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 1, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 2, size*((float(i)/10))))
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 2, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 3, size*((float(i)/10))))
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 3, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 4, size*((float(i)/10))))
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 4, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 5, size*((float(i)/10))))
		st.add_vertex(Vector3(0,0,0))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 5, size*((float(i)/10))))
		st.add_vertex(utils.sized_vec3_from_r_vec2(TAU / 6 * 0, size*((float(i)/10))))
	$GoalMesh.mesh = st.commit()
	$GoalMesh.position = hex_to_pixel(goal_hex)
	
	var points = PoolVector2Array()
	for i in range(6):
		var r = TAU / 6 * i
		points.append(utils.sized_vec_from_r(r, size*0.5))
		
	var shape = ConvexPolygonShape2D.new()
	shape.points = points
	$GoalArea/Collision.shape = shape
	$GoalArea.position = hex_to_pixel(goal_hex)

func _should_draw(hex, wall):
	if wall == 5:
		return (hex.x != map_radius and hex.y != -map_radius)
	elif wall == 0:
		return hex.z != -map_radius and hex.x != map_radius
	elif wall == 1:
		return hex.y != map_radius and hex.z != -map_radius
	return false

func hex_to_pixel(hex: Vector3) -> Vector2:
	var x = layout[0] * hex.x + layout[1] * hex.y
	var y = layout[2] * hex.x + layout[3] * hex.y
	return Vector2(x, y) * size + origin

func pixel_to_hex(pos):
	var pt = Vector2((pos.x - origin.x) / size.x, (pos.y - origin.y) / size.y)
	var q = layout_inv[0] * pt.x + layout_inv[1] * pt.y
	var r = layout_inv[2] * pt.x + layout_inv[3] * pt.y
	return _round_hex(Vector3(q, r, -q - r))

func _round_hex(hex):
	var rx = round(hex.x)
	var ry = round(hex.y)
	var rz = round(hex.z)

	var x_diff = abs(rx - hex.x)
	var y_diff = abs(ry - hex.y)
	var z_diff = abs(rz - hex.z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry-rz
	elif y_diff > z_diff:
		ry = -rx-rz
	else:
		rz = -rx-ry

	return Vector3(rx, ry, rz)