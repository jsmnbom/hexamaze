extends CanvasLayer

var goal_line_height = 0.0
var goal_line_x = 0.0 setget _set_goal_line_x
var level setget _set_level

var difficulties = [
	'tutorial',
	'very_easy', 'quite_easy', 'easy',
	'easy_normal', 'normal', 'harder_normal', 'hard_normal',
	'hard', 'quite_hard', 'harder', 'very hard', 'hardest'
]

func _ready():
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize()
	

func _set_level(new_level):
	level = new_level
	if level == 0:
		$DifficultyLabel.set_text(difficulties[0])
	else:
		$Controls.hide()
		$DifficultyLabel.set_text('%s_%s' % [get_difficulty(floor((level-1)/2)+1), (level-1)%2])

func get_difficulty(diff):
	if diff < difficulties.size():
		return difficulties[diff]
	else:
		var s = difficulties[-1]
		for _i in range(diff-difficulties.size()+1):
			s += 'est'
		return s

func _set_goal_line_x(new_goal_line_x):
	goal_line_x = clamp(new_goal_line_x * get_viewport().size.x, 5, get_viewport().size.x-5)
	$GoalLine.points = PoolVector2Array([Vector2(goal_line_x, 0), Vector2(goal_line_x, goal_line_height)])

func _on_resize():
	commit_goal_distance()
	
	$GoalLine.width = clamp(get_viewport().size.x / 300, 2, 10)
	
	$DifficultyLabel.rect_size.x = get_viewport().size.x - 10
	$DifficultyLabel.rect_position = Vector2(5, goal_line_height)
	
	var s = float(get_viewport().size.x)/$Controls.rect_size.x / 4
	$Controls.rect_scale = Vector2(s, s)
	$Controls.rect_position = get_viewport().size - $Controls.rect_size * $Controls.rect_scale
	
	$AbilityDisplay.size = 35
	$AbilityDisplay.rect_position = get_viewport().size
	$AbilityDisplay._on_resize()

func commit_goal_distance():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_uv(Vector2(0, 0))
	var segments = 10
	var size = Vector2(float(get_viewport().size.x)/segments, get_viewport().size.y/45)
	for i in range(segments):
		st.add_color(Color.from_hsv(range_lerp(size.x*i+size.x/2, 0, get_viewport().size.x, 0.5, 1.0), 0.4, 0.5))
		st.add_vertex(Vector3(size.x*i, 0, 0))
		st.add_vertex(Vector3(size.x*i, size.y, 0))
		st.add_vertex(Vector3(size.x*i+size.x*(i+1), 0, 0))
		st.add_vertex(Vector3(size.x*i+size.x*(i+1), size.y, 0))

		st.add_index(0+i*4);
		st.add_index(1+i*4);
		st.add_index(2+i*4);
		
		st.add_index(1+i*4);
		st.add_index(2+i*4);
		st.add_index(3+i*4);
	var wall_mesh = st.commit()
	$GoalDistance.mesh = wall_mesh
	
	goal_line_height = size.y