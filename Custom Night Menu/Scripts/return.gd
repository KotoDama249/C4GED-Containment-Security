extends Label

func _ready() -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.is_action_pressed("uiClick"):
		get_tree().change_scene_to_file("res://Scenes/title.tscn")
