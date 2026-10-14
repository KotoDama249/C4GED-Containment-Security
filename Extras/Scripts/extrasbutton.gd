extends Label

func _ready() -> void:
	connect ("mouse_entered", mouseEntered)

func mouseEntered() -> void:
	if $"../Arrow Back".position.y != position.y:
		$"../Switch Noise".play()
		
	$"../Arrow Back".position.y = position.y

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("uiClick"):
		if name == "Characters":
			pass
		
		if name == "Concepts":
			pass
		
		if name == "ExtraStuff":
			pass
			
		if name == "Minigames":
			pass
			
		if name == "Return":
			get_tree().change_scene_to_file("res://Scenes/title.tscn")
			
