extends Node2D

func _ready():
	$Title.connect('start_game', self, '_on_start_game')
	
func _on_start_game():
	$Title.queue_free()
	add_child(load('res://src/Game/Game.tscn').instance())