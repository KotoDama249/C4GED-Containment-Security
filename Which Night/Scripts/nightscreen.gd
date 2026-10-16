extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	$Timer.connect("timeout", timerTimeout)

func timerTimeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/nightgameplay.tscn")
