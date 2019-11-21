extends Node

var rng = RandomNumberGenerator.new()

func rng_sample(n, _list):
	var list = _list.duplicate()
	var sample = []
	for _i in range(n):
		var x = rng.randi() % list.size()
		sample.append(list[x])
		list.remove(x)
	return sample

func rng_choose(list):
	return list[rng.randi() % list.size()]

func _ready():
	pass

func rng_random_seed():
	rng.randomize()
	prints('rng seed:', rng.seed)

func sized_vec_from_r(r, s):
	return Vector2(cos(r), sin(r)) * s
	
func sized_vec3_from_r(r, s):
	return Vector3(cos(r), sin(r), 0) * s
	
func sized_vec3_from_r_vec2(r, s):
	return Vector3(cos(r), sin(r), 0) * Vector3(s.x, s.y, 0)
	
func vec3_duplicate(v):
	return Vector3(v.x, v.y, v.z)