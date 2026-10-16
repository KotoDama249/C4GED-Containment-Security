extends RefCounted

class_name VNChar

var attr_address : int
var attr_parent : Scripted
var attr_name : String
var attr_color : Color

# Portrait: a single spritesheet of faces rather than separate layers.
# Not required -- a character with no sheet just won't draw anything when entered.
# attr_faces maps a face name to a (col, row) cell in that sheet.
var attr_face_sheet : Texture2D
var attr_face_frame_size : Vector2i
var attr_faces : Dictionary[String, Vector2i]

func _init(address : int, parent : Scripted) -> void:
	self.attr_address = address
	self.attr_parent = parent

func color(color : Color) -> VNChar:
	self.attr_color = color
	return self

func says(text : String) -> VNChar:
	assert(self.attr_parent != null)
	self.attr_parent.says(text, self.attr_address)
	return self

func name(name : String) -> VNChar:
	self.attr_name = name
	return self

func face_sheet(texture : Texture2D, frame_size : Vector2i) -> VNChar:
	self.attr_face_sheet = texture
	self.attr_face_frame_size = frame_size
	return self

func face(face_name : String, col : int, row : int = 0) -> VNChar:
	self.attr_faces[face_name] = Vector2i(col, row)
	return self
