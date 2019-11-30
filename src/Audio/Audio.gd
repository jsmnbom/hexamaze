extends Node2D

var icon_on = load('res://assets/sound_on.png')
var icon_off = load('res://assets/sound_off.png')

var on = true

func _ready():
	$BG.play()
	
	get_tree().root.connect('size_changed', self, '_on_resize')
	_on_resize(0)
	
func _on_resize(progress_height):
	$Layer/Toggle.rect_position = Vector2(4, get_viewport().size.y - 32-4-progress_height)

func _on_Toggle_pressed():
	on = !on
	$BG.stream_paused = !on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), !on)
	
	$Layer/Toggle.texture_normal = icon_on if on else icon_off

func play_hole():
	$Hole.play()
	
func play_pickup():
	$Pickup.play()
	
func start_ticking():
	$Ticking.play()
	
func stop_ticking():
	$Ticking.stop()
	
func play_activate():
	$Activate.play()