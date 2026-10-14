extends Label

const extras : PackedScene = preload("res://Scenes/extras.tscn")
const customnight : PackedScene = preload("res://Scenes/customnight.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioPersist.play_music()
	connect ("mouse_entered", mouseEntered)
	$"../Newspaper/AnimationPlayer".animation_finished.connect(newspaperDone)

func mouseEntered() -> void:
	if $"../Arrow".position.y != position.y:
		$"../../Audio/Switch Noise".play()
		
	$"../Arrow".position.y = position.y

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("uiClick"):
		if name == "NewGame":
			AudioPersist.stop_music()
			get_tree().paused = true
			$"../Newspaper".visible = true
			$"../Newspaper/AnimationPlayer".play("show_newspaper")
		
		if name == "Continue":
			AudioPersist.stop_music()
		
		if name == "Extras":
			get_tree().change_scene_to_packed(extras)
			
		if name == "Night 6":
			AudioPersist.stop_music()
			
		if name == "Custom Night":
			get_tree().change_scene_to_packed(customnight)
			
	if event is InputEventMouseButton and event.double_click:
		if event.is_action_pressed("uiClick") and name == "Quit":
			get_tree().quit()
			AudioPersist.stop_music()
			
func newspaperDone(_animName : StringName) -> void:
	if name == "NewGame":
		get_tree().change_scene_to_file("res://Scenes/whichnight.tscn")
			
