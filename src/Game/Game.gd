extends Node2D

onready var ABILITY_TYPE = $HUD/AbilityDisplay.TYPE

var root
var root_size = Vector2()
var pixilation = 4

var player_speed = 75
var player_paused = true

var mouse_down = false
var touch_position
var touches = []

var level = 3

var debug = false

onready var pixilation_vpc = $GameLayer/PixilationVPC
onready var pixilation_vp = $GameLayer/PixilationVPC/PixilationVP
onready var bg = $GameLayer/PixilationVPC/PixilationVP/BG
onready var player = $GameLayer/PixilationVPC/PixilationVP/Player
onready var player_sprite = $HUD/PlayerSprite
onready var map = $GameLayer/PixilationVPC/PixilationVP/Map
onready var goal_area = $GameLayer/PixilationVPC/PixilationVP/Map/GoalArea
onready var hud = $HUD
onready var debug_label = $HUD/DebugLabel
onready var fade = $FadeLayer/Fade
onready var map_walls = $GameLayer/PixilationVPC/PixilationVP/Map/WallMesh
onready var player_light = $GameLayer/PixilationVPC/PixilationVP/Player/Light

func _ready():
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize()
	
	goal_area.connect('body_entered', self, '_on_goal_area_body_enter')
	
	events.connect('ability', self, '_on_ability')
	
	map.generate(1)
	hud.level = 0
	fade.fade_in(0.5, [self, 'unpause_player'])
	
	if OS.is_debug_build():
		debug = true
		debug_label.show()

func unpause_player():
	player_paused = false

func _on_resize():
	root = get_tree().root
	root_size = root.size
	pixilation_vpc.rect_position = Vector2()
	pixilation_vpc.rect_size = root_size
	pixilation_vp.size = root_size / pixilation
	bg.rect_size = root_size / pixilation
	fade.rect_size = root_size
	
	player_sprite.position = root_size / 2
	
	var size_diff = map._on_resize()
	
	var root_min = min(root_size.x, root_size.y)
	player_speed = root_min / 8
	player.size = root_min / 65 / pixilation
	
	player._on_resize()
	player.position *= size_diff
	
func _physics_process(_delta):
	if debug:
		var player_pos_hex = map.pixel_to_hex(player.position)
		debug_label.text = 'FPS: %s\nPlayer.pos: (%s, %s)\nPlayer.pos.hex: (%s, %s, %s)\nMap.map_radius: %s' % [Engine.get_frames_per_second(), round(player.position.x), round(player.position.y), player_pos_hex.x, player_pos_hex.y, player_pos_hex.z, map.map_radius]
	
	if not player_paused:
		if mouse_down:
			var move = root.get_mouse_position() - root_size / 2
			player.move_and_slide(move.normalized() * player_speed)
		elif touches.size() > 0:
			var move = touch_position - root_size / 2
			player.move_and_slide(move.normalized() * player_speed)
		else:
			var velocity = Vector2()
			if Input.is_action_pressed('up'):
				velocity.y = -1
			if Input.is_action_pressed('down'):
				velocity.y = 1
			if Input.is_action_pressed('right'):
				velocity.x = 1
			if Input.is_action_pressed('left'):
				velocity.x = -1
	
			player.move_and_slide(velocity.normalized() * player_speed)

	var trans = Transform2D(0, player.position - root_size / 2 / pixilation)
	pixilation_vp.canvas_transform = trans.affine_inverse()
	bg.rect_position = trans.origin
	map.vp_top_left = trans.origin
	
	var distance = player.position.distance_to(map.goal_position)
	var x = range_lerp(distance, 0, map.goal_distance_size, 1, 0)
	bg.color = Color.from_hsv(range_lerp(x, 0, 1, 0.5, 1.0), 0.4, 1)
	hud.goal_line_x = x

func _unhandled_input(event):
	if event.is_action_released('debug_toggle'):
		debug = not debug
		debug_label.visible = debug
	
	if event.is_action_pressed('mouse_move'):
		mouse_down = true
	if event.is_action_released('mouse_move'):
		mouse_down = false
	
	if event is InputEventScreenTouch:
		if event.pressed:
			touches.append(event.index)
			touch_position = event.position
		else:
			touches.erase(event.index)
			return
			
	if event is InputEventScreenDrag:
		if event.index == touches[-1]:
			touch_position = event.position

func next_level():
	player_paused = true
	fade.fade_out(1.0, [self, '_next_level'])
	
func _next_level():
	level += 1
	hud.level = level
	
	player.position = Vector2()
	
	map.generate(floor((level-1)/2)+1)
	
	fade.fade_in(0.25, [self, 'unpause_player'])
	
func _on_goal_area_body_enter(body):
	if body == player and not player_paused:
		next_level()
		
func _on_ability(msg):
	match msg:
		{'type': ABILITY_TYPE.WALL_WALK, 'activated': var activated}:
			player.set_collision_mask_bit(1, !activated)
		{'type': ABILITY_TYPE.LIGHT, 'activated': var activated}:
			map_walls.modulate = Color(0,0,0)
			map_walls.visible = activated
			player_light.visible = !activated
		{'type': ABILITY_TYPE.BREADCRUMBS, 'i': var i}:
			map.add_breadcrumb(player.position, i)
		{'type': ABILITY_TYPE.WALL_LOOK, 'activated': var activated}:
			map_walls.modulate = Color(0,0,0)
			map_walls.visible = activated
			player_light.shadow_gradient_length = 5 if activated else 0
		{'type': ABILITY_TYPE.WALL_SHOW, 'activated': var activated}:
			map_walls.modulate = Color(1,1,1)
			map_walls.visible = activated
			
			