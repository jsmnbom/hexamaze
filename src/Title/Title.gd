extends Node2D


func _ready():
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize()
	
	$Tween.interpolate_property($TaglineLabel, 'modulate:a', 1.0, 0.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT, 0.5)
	$Tween.interpolate_property($PressLabel, 'modulate:a', 0.0, 1.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_OUT, 1.0)
	$Tween.start()
	
	var version
	var version_file = File.new()
	if version_file.file_exists('res://VERSION'):
		version_file.open("res://VERSION", File.READ)
		version = version_file.get_line()
	elif OS.is_debug_build():
		version = 'DEBUG BUILD'
	else:
		version = 'ERROR: VERSION NOT FOUND'
	OS.set_window_title('HexaMaze %s' % version)
	
func _on_resize():
	var root_size = get_viewport().size
	$BG.rect_size = root_size
	
	var pixilation = root_size.x/125
	var one_third = 1.0/3.0
	
	var title_width = root_size.x
	if title_width/1.8 > root_size.y:
		title_width = root_size.y * 1.8
	var padding = Vector2(title_width / 20, title_width/20)
	var title_square = Vector2(title_width, title_width)
	
	var center_padding = Vector2((root_size.x - title_width) /2, (root_size.y - title_width*(1.5/3.0)) /2)
	print(center_padding)
	pixilation -= (center_padding.x*2) / 125
	
	$PixilationVPC.rect_position = center_padding + padding
	$PixilationVPC.rect_size = title_square * one_third - padding
	$PixilationVPC.rect_pivot_offset = $PixilationVPC.rect_size / 2
	$PixilationVPC/PixilationVP.size = ($PixilationVPC.rect_size / pixilation)
	$PixilationVPC/PixilationVP/Hexa.size = $PixilationVPC/PixilationVP.size / 2
	$PixilationVPC/PixilationVP/Hexa._on_resize()
	
	$MazeLabel.rect_position = Vector2(title_width * one_third + padding.x, padding.y) + center_padding
	$MazeLabel.rect_scale = Vector2(title_width * (2.0/3.0) - padding.x*2, title_width * one_third - padding.y) / $MazeLabel.rect_size
	
	$TaglineLabel.rect_position = Vector2(padding.x, title_width * one_third + padding.y + center_padding.y)
	var tagline_scale = (root_size.x - padding.x * 2) / $TaglineLabel.rect_size.x
	$TaglineLabel.rect_scale = Vector2(tagline_scale, tagline_scale)
	
	$PressLabel.rect_position = Vector2(padding.x*3, title_width * one_third + padding.y + center_padding.y)
	var press_scale = (root_size.x - padding.x * 6) / $PressLabel.rect_size.x
	$PressLabel.rect_scale = Vector2(press_scale, press_scale)
	
func _unhandled_input(event):
	if event is InputEventKey or event is InputEventScreenTouch or event is InputEventMouseButton:
		get_tree().change_scene_to(load('res://src/Game/Game.tscn'))
	