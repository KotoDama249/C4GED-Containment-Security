extends RefCounted

class_name VNTree

class Child extends RefCounted:
	var parent : Child : set = _set_parent
	var childs : Array[Child]
	
	func _set_parent(_parent : Child) -> void:
		if self.parent == _parent or _parent == self or _parent.parent == self:
			return
		
		parent = _parent
		return
	
	func _init() -> void:
		return

class DialogText extends Child:
	var author : int
	var text : String
	
	func _init(author : int, text : String) -> void:
		self.author = author
		self.text = text

class WaitTime extends Child:
	var async : bool
	var time : float
	
	func _init(async : bool, time : float) -> void:
		self.async = async
		self.time = time

class Entry extends Child:
	var text : String
	var title : String
	var placeholder : String
	var hint : String
	var ok : Callable
	var required : bool
	
	func _init(text : String, title : String, placeholder : String, hint : String, ok : Callable, required : bool) -> void:
		self.text = text
		self.title = title
		self.placeholder = placeholder
		self.hint = hint
		self.ok = ok
		self.required = required

class Jump extends Child:
	var callback : Callable
	var params : Array
	
	func _init(callback : Callable, params : Array) -> void:
		self.callback = callback
		self.params = params

class Choice extends Child:
	var option : VNOption
	
	func _init(option : VNOption) -> void:
		self.option = option

class Yield extends Child:
	var emit : bool
	
	func _init(emit : bool) -> void:
		self.emit = emit

class Opacity extends Child:
	var opacity : float
	
	func _init(opacity : float) -> void:
		self.opacity = opacity

# Shows/moves a character's portrait into one of the "left"/"center"/"right"
# slots, optionally switching their face at the same time.
class Enter extends Child:
	var who : VNChar
	var position : String
	var face_name : String
	
	func _init(who : VNChar, position : String, face_name : String) -> void:
		self.who = who
		self.position = position
		self.face_name = face_name

# Clears whoever is currently shown in a given "left"/"center"/"right" slot.
class Exit extends Child:
	var position : String
	
	func _init(position : String) -> void:
		self.position = position

# Hands control to another dialogue script, reusing the same text/portrait
# nodes instead of starting a brand new scene.
class Goto extends Child:
	var target : GDScript
	
	func _init(target : GDScript) -> void:
		self.target = target

# Shows a background (or a CG, if no characters are currently entered) in
# the one shared background slot, optionally switching to a named variant.
class ShowBackground extends Child:
	var who : VNBackground
	var variant_name : String
	
	func _init(who : VNBackground, variant_name : String) -> void:
		self.who = who
		self.variant_name = variant_name

var root : Child = Child.new()
