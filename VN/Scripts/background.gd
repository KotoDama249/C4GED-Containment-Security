extends RefCounted

class_name VNBackground

var attr_address : int
var attr_parent : Scripted
var attr_name : String # internal label only (e.g. for a dropdown) -- never shown to the player

# Same one-spritesheet-of-named-cells pattern as a character's face sheet.
var attr_sheet : Texture2D
var attr_frame_size : Vector2i
var attr_variants : Dictionary[String, Vector2i]

func _init(address : int, parent : Scripted) -> void:
	self.attr_address = address
	self.attr_parent = parent

func name(name : String) -> VNBackground:
	self.attr_name = name
	return self

func sheet(texture : Texture2D, frame_size : Vector2i) -> VNBackground:
	self.attr_sheet = texture
	self.attr_frame_size = frame_size
	return self

func variant(variant_name : String, col : int, row : int = 0) -> VNBackground:
	self.attr_variants[variant_name] = Vector2i(col, row)
	return self
