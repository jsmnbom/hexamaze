extends Node
class_name MazeGen

var map = {}
var visited = []
var remaining = 0
var goal_hex

const hex_directions = [
	Vector3( 1, -1,  0), Vector3( 1,  0, -1), Vector3( 0,  1, -1),
	Vector3(-1,  1,  0), Vector3(-1,  0,  1), Vector3( 0, -1,  1)
]

func generate(map_radius):
	print('Generating maze')
	var start_time = OS.get_ticks_msec()
	
	map = {}
	visited = []
	remaining = 0
	utils.rng_random_seed()
	
	for q in range(-map_radius, map_radius+1):
		var r1 = max(-map_radius, -q - map_radius)
		var r2 = min(map_radius, -q + map_radius)
		for r in range(r1, r2+1):
			var i = Vector3(q, r, -q-r)
			map[i] = [true, true, true, true, true, true]
			remaining += 1
			
	var edges = []
	for hex in map.keys():
		if (abs(hex.x)+abs(hex.y)+abs(hex.x)) / 2 == map_radius:
			edges.append(hex)
	goal_hex = utils.rng_choose(edges)
	
	_generate_maze()
	
	_create_rooms()
	
	print('Maze generation done. Took %s' % (OS.get_ticks_msec() - start_time))
	return [goal_hex, map]

func _create_rooms():
	for _i in range(map.size() / 20):
		var center = utils.rng_choose(map.keys())
		var raw_neighbors = get_neighbors(center, true)
		var neighbors = utils.rng_sample(min(utils.rng_choose([2,2,2,3,3,3,4,4,5]), raw_neighbors.size()), raw_neighbors)
		for neighbor in neighbors:
			map[center][neighbor[1]] = false
			map[neighbor[0]][(neighbor[1]+3)%6] = false

func _find_unvisited_neighbor(current: Vector3):
	var neighbors = []
	for i in range(hex_directions.size()):
		var direction = hex_directions[i]
		var neighbor = current + direction
		if not neighbor in visited and neighbor in map.keys():
			neighbors.append([neighbor, (i+5)%6])
	if neighbors.size() > 0:
		return utils.rng_choose(neighbors)
	return null

func get_neighbors(hex, ignore_walls=false):
	var neighbors = []
	for i in range(hex_directions.size()):
		var direction = hex_directions[i]
		var neighbor = hex + direction
		if neighbor in map.keys() and (not map[hex][(i+5)%6] or ignore_walls):
			neighbors.append([neighbor, (i+5)%6])
	return neighbors

func _generate_maze():
	var current = utils.vec3_duplicate(goal_hex)
	prints('Start hex: ', current)
	
	var stack = []
	
	while remaining > 1:
		stack.append(current)
		visited.append(current)

		var neighbor_data = _find_unvisited_neighbor(current)

		if neighbor_data == null:
			stack.pop_back()
			current = stack.pop_back()
		else:
			var neighbor = neighbor_data[0]
			var wall = neighbor_data[1]
			map[current][wall] = false
			current = neighbor
			map[current][(wall+3)%6] = false
			remaining -= 1