extends Node2D

var root
var root_size
var pixilation = 4

var player_speed = 75
var player_paused = true

var level = 0

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

func _ready():
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize()
	
	goal_area.connect('body_entered', self, '_on_goal_area_body_enter')
	
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
	
	map._on_resize()
	
	var root_min = min(root_size.x, root_size.y)
	player_speed = root_min / 8
	player.size = root_min / 65 / pixilation
	
	player._on_resize()
	
func _physics_process(_delta):
	if debug:
		debug_label.text = 'FPS: %s\nPlayer.pos: (%s, %s)\nMap.map_radius: %s' % [Engine.get_frames_per_second(), round(player.position.x), round(player.position.y), map.map_radius]
	
	if not player_paused:
		if Input.is_action_pressed('mouse_move'):
			var move = root.get_mouse_position() - root_size / 2
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
	if event.is_action_pressed("debug_toggle"):
		debug = not debug
		debug_label.visible = debug

func next_level():
	player_paused = true
	fade.fade_out(1.0, [self, '_next_level'])
	
func _next_level():
	level += 1
	hud.level = level
	
	player.position = Vector2(0,0)
	
	map.generate(floor((level-1)/2)+1)
	
	fade.fade_in(0.25, [self, 'unpause_player'])
	
func _on_goal_area_body_enter(body):
	if body == player and not player_paused:
		next_level()
