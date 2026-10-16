extends Node

# Attach this once to your dialogue box's controller node and wire up the
# exports below in the Inspector, same as you did for the old per-script
# exports. Every dialogue script -- including the first one -- is now the
# same uniform shape: extends RefCounted, func build(s : Scripted) -> void.
# There's nothing special about "the first script" anymore; it's just
# whatever you pass to start_dialogue() first, or set as first_script
# below to auto-run on _ready().

@export var text : RichTextLabel
@export var author : Label
@export var portrait_left : Control
@export var portrait_center : Control
@export var portrait_right : Control
@export var background_slot : Control

# Optional: a script to auto-start as soon as this node enters the tree.
# Leave empty if dialogue should only start when something else triggers it
# (e.g. an interaction) -- in that case, call start_dialogue() yourself.
@export var first_script : GDScript

var s : Scripted

# A dialogue script's build(s) wires up choice/entry Callables bound to
# *this* object (e.g. "_on_choice1_opt0"), so something has to keep it alive
# for as long as those Callables might still fire -- otherwise it's freed
# the moment start_dialogue() returns and clicking a choice crashes trying
# to call a method on a null instance. Holding it here is all that's needed.
var _builder : RefCounted

func _ready() -> void:
	if first_script:
		start_dialogue(first_script)

# Call this to begin a dialogue script from scratch -- e.g. from an
# interaction signal, not just once at scene start. Always builds a fresh
# Scripted instance, so calling this again mid-conversation cleanly resets
# rather than mixing with whatever was previously running.
func start_dialogue(target : GDScript) -> void:
	# The new Scripted starts with empty portrait-tracking, but whoever was
	# already shown from the PREVIOUS dialogue is still sitting there as an
	# actual child of these Controls -- nothing frees it on its own, so clear
	# it out here rather than leaving old portraits stuck on screen.
	for slot in [portrait_left, portrait_center, portrait_right, background_slot]:
		if slot:
			for child in slot.get_children():
				child.queue_free()
	
	s = Scripted.new()
	s.from = self
	s.portrait_left = portrait_left
	s.portrait_center = portrait_center
	s.portrait_right = portrait_right
	s.background_slot = background_slot
	
	_builder = target.new()
	if _builder.has_method("build"):
		_builder.build(s)
	else:
		push_warning("DialogueHandler: %s has no build(s) method." % target.resource_path)
	
	s.start()

func _process(delta: float) -> void:
	if not s:
		return
	
	if Input.is_action_just_pressed("ui_accept"):
		s.confirm.emit()
	
	var ch = s.get_character()
	text.text = s.text_output
	text.modulate.a = s.opacity_output
	text.visible_characters = text.get_total_character_count() - s.text_output.length() + int(s.vrat_output * s.text_output.length())
	
	author.text = ch.attr_name if ch != null else ""
	author.modulate = ch.attr_color if ch != null else Color.WHITE
	author.modulate.a = s.opacity_output
