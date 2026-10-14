extends Node

@onready var hitboxballs: Area2D = $Area2D
@onready var description_panel: Panel = $"../BGPanel"
@onready var description_label: Label = $"../DescriptionText"

@export_multiline var character_description: String = "Marley Text."

# A global tracker shared across characters to keep track of active hovers
static var active_hover_count: int = 0

func _ready() -> void:
	hitboxballs.mouse_entered.connect(_on_mouse_entered)
	hitboxballs.mouse_exited.connect(_on_mouse_exited)
	
	if description_panel.visible:
		description_panel.visible = false
		description_label.text = ""

func _on_mouse_entered() -> void:
	# Increment count of hovered items and immediately show info
	active_hover_count += 1
	description_label.text = character_description
	description_panel.visible = true

func _on_mouse_exited() -> void:
	# Decrement count, but wait a frame to see if we just entered another hitbox
	active_hover_count = max(0, active_hover_count - 1)
	
	# Small delay using a tree timer to check if we've landed on a new character
	await get_tree().process_frame
	
	if active_hover_count == 0:
		description_label.text = ""
		description_panel.visible = false
