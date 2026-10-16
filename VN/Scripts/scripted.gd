extends RefCounted

class_name Scripted

enum Error {
	ERR = -1,
	OK = 0
}

const NO_CHAR := -1
const PORTRAIT_POSITIONS := ["left", "center", "right"]

signal confirm
signal unlock_context

var from : Node
var char : Dictionary[int, VNChar]
var tree : VNTree
var dialog_displaying : bool
var double_layer : bool
var layer_child : VNTree.Child

var char_output : int = NO_CHAR
var text_output : String
var vrat_output : float = 0.0
var opacity_output : float = 1.0
var screen : Window

# Consumer-provided Controls, one per portrait slot. Set these (e.g. in
# _ready(), after @export vars are populated) before using enter()/exit().
var portrait_left : Control
var portrait_center : Control
var portrait_right : Control

# Internal bookkeeping for enter()/exit() -- which VNChar currently occupies
# each slot, and the layer-stack node currently sitting in that slot's Control.
var portrait_occupant : Dictionary[String, VNChar]
var portrait_node : Dictionary[String, Control]

# Consumer-provided Control for the single background/CG slot, set the same
# way as the portrait slots.
var background_slot : Control
var bg : Dictionary[int, VNBackground]
var background_node : TextureRect

# Each goto() target is a throwaway RefCounted whose build(s) wires up
# choice/entry Callables bound to itself -- something has to keep it alive
# for as long as those Callables might still fire, same reason
# DialogueHandler keeps its own _builder around.
var _goto_builders : Array = []

# Which choice options have been picked this session, keyed by "choice
# label::option label". Lives on this Scripted instance, so it naturally
# resets whenever DialogueHandler builds a fresh one (leaving and
# re-entering the scene) rather than needing an actual save file.
var _seen_options : Dictionary[String, bool]

func _count_vratio(progress : int = 0, delay := 0.02) -> void:
	if not dialog_displaying:
		return
	
	var cur := float(progress) / float(text_output.length())
	vrat_output = cur
	
	if vrat_output < text_output.length() / text_output.length():
		if not from or not from.get_tree():
			return
		
		await from.get_tree().create_timer(delay).timeout
		_count_vratio(progress + 1, delay)

func _init() -> void:
	self.tree = VNTree.new()
	return

func pause() -> void:
	register(VNTree.Yield.new(false))
	return

func resume() -> void:
	register(VNTree.Yield.new(true))
	return

func layer_init() -> void:
	layer_child = VNTree.Child.new()
	double_layer = true

func layer_start() -> void:
	await exec(layer_child)
	layer_quit()

func layer_quit() -> void:
	layer_child = null
	double_layer = false

func hide() -> void:
	register(VNTree.Opacity.new(0.0))

func show() -> void:
	register(VNTree.Opacity.new(1.0))

func alert(text : String, title := "") -> void:
	OS.alert(text, title)

func character() -> VNChar:
	var address := randi()
	
	if char.has(address):
		randomize()
		return character()
	
	char[address] = VNChar.new(address, self)
	return char[address]

func get_character() -> VNChar:
	if char_output != NO_CHAR:
		return char[char_output]
	return null

func background() -> VNBackground:
	var address := randi()
	
	if bg.has(address):
		randomize()
		return background()
	
	bg[address] = VNBackground.new(address, self)
	return bg[address]

func register(child : VNTree.Child, parent := tree.root) -> void:
	assert(tree != null and parent != null)
	
	if double_layer:
		if layer_child:
			parent = layer_child
	
	child.parent = parent
	parent.childs.push_back(child)
	return

func choices(label : String) -> VNOption:
	var o := VNOption.new(label, self)
	register(VNTree.Choice.new(o))
	return o

func says(text : String, character : int = NO_CHAR) -> void:
	show()
	register(VNTree.DialogText.new(character, text))
	return

func wait(time : float, async := false) -> void:
	register(VNTree.WaitTime.new(async, time))
	return

func entry(text : String, placeholder := "", hint := "", required : bool = true, ok : Callable = Callable()) -> void:
	register(VNTree.Entry.new(text, "", placeholder, hint, ok, required))
	return

func jump(callback : Callable, params := []) -> void:
	register(VNTree.Jump.new(callback, params))
	return

func enter(who : VNChar, position : String, face_name := "") -> void:
	register(VNTree.Enter.new(who, position, face_name))
	return

func exit(position : String) -> void:
	register(VNTree.Exit.new(position))
	return

func goto(target : GDScript) -> void:
	register(VNTree.Goto.new(target))
	return

func show_background(who : VNBackground, variant_name := "") -> void:
	register(VNTree.ShowBackground.new(who, variant_name))
	return

func _portrait_slot(position : String) -> Control:
	match position:
		"left": return portrait_left
		"center": return portrait_center
		"right": return portrait_right
	return null

func _do_exit(position : String) -> void:
	if portrait_node.has(position):
		portrait_node[position].queue_free()
		portrait_node.erase(position)
	portrait_occupant.erase(position)

func _set_face(stack : Control, who : VNChar, face_name : String) -> void:
	if not who.attr_face_sheet:
		return
	
	var face_rect := stack.get_node_or_null("Face") as TextureRect
	if not face_rect:
		return
	
	if face_name != "" and not who.attr_faces.has(face_name):
		push_warning("Scripted: '%s' has no variation named '%s'; using cell 0, 0." % [who.attr_name, face_name])
	var coords : Vector2i = who.attr_faces.get(face_name, Vector2i.ZERO)
	var atlas := AtlasTexture.new()
	atlas.atlas = who.attr_face_sheet
	atlas.region = Rect2(
		coords.x * who.attr_face_frame_size.x,
		coords.y * who.attr_face_frame_size.y,
		who.attr_face_frame_size.x,
		who.attr_face_frame_size.y
	)
	face_rect.texture = atlas

func _do_enter(who : VNChar, position : String, face_name : String) -> void:
	if not PORTRAIT_POSITIONS.has(position):
		push_warning("Scripted: unknown portrait position '%s' (use left/center/right)." % position)
		return
	
	var slot := _portrait_slot(position)
	if not slot:
		push_warning("Scripted: portrait_%s is not set, so there's nowhere to show this character." % position)
		return
	
	# If this character is already shown in a different slot, clear that one.
	for other_pos in portrait_occupant.keys():
		if other_pos != position and portrait_occupant[other_pos] == who:
			_do_exit(other_pos)
	
	var needs_rebuild := not portrait_occupant.has(position) or portrait_occupant[position] != who
	
	if needs_rebuild:
		_do_exit(position)
		
		var stack := Control.new()
		stack.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# One TextureRect per character; _set_face() picks the cell from the sheet.
		if who.attr_face_sheet:
			var face_rect := TextureRect.new()
			face_rect.name = "Face"
			face_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stack.add_child(face_rect)
		
		slot.add_child(stack)
		portrait_node[position] = stack
		portrait_occupant[position] = who
	
	_set_face(portrait_node[position], who, face_name)

func _do_show_background(who : VNBackground, variant_name : String) -> void:
	if not background_slot:
		push_warning("Scripted: background_slot is not set, so there's nowhere to show this background.")
		return
	
	if not background_node:
		background_node = TextureRect.new()
		background_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background_slot.add_child(background_node)
	
	if not who.attr_sheet:
		return
	
	if variant_name != "" and not who.attr_variants.has(variant_name):
		push_warning("Scripted: background '%s' has no variant named '%s'; using cell 0, 0." % [who.attr_name, variant_name])
	var coords : Vector2i = who.attr_variants.get(variant_name, Vector2i.ZERO)
	var atlas := AtlasTexture.new()
	atlas.atlas = who.attr_sheet
	atlas.region = Rect2(
		coords.x * who.attr_frame_size.x,
		coords.y * who.attr_frame_size.y,
		who.attr_frame_size.x,
		who.attr_frame_size.y
	)
	background_node.texture = atlas

func exec(child : VNTree.Child) -> int:
	if not child:
		return Error.OK
	
	if child is VNTree.DialogText:
		dialog_displaying = true
		vrat_output = 0.0
		char_output = child.author if char.has(child.author) else NO_CHAR
		text_output = child.text
		_count_vratio() # runs on its own timers; not awaited here so a press can interrupt it
		
		await confirm
		if vrat_output < 1.0:
			# Line wasn't done typing yet -- finish it instantly instead of
			# advancing, and wait for a second press to actually move on.
			dialog_displaying = false
			vrat_output = 1.0
			await confirm
		else:
			dialog_displaying = false
	
	elif child is VNTree.WaitTime:
		if child.async:
			from.get_tree().create_timer(child.time).timeout.connect(func() -> void:
				for ch in child.childs:
					await exec(ch))
		else:
			await from.get_tree().create_timer(child.time).timeout
	
	elif child is VNTree.Entry:
		var e := AcceptDialog.new()
		var l := LineEdit.new()
		l.text = child.placeholder
		l.placeholder_text = child.hint
		l.text_submitted.connect(func(text : String) -> void:
			e.get_ok_button().grab_focus())
		e.title = child.title
		e.dialog_text = child.text
		#e.exclusive = true
		e.always_on_top = true
		e.dialog_close_on_escape = false
		e.add_child(BoxContainer.new())
		(e.get_child(0) as BoxContainer).vertical = true
		e.get_child(1, true).reparent(e.get_child(0), true)
		(e.get_child(0) as BoxContainer).add_child(l)
		e.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		e.borderless = true
		e.extend_to_title = true
		screen = e
		from.add_child(e)
		e.show()
		await e.confirmed
		e.queue_free()
		if child.required and l.text.length() < 1:
			return await exec(child)
		else:
			child.ok.call(l.text)
	
	elif child is VNTree.Jump:
		if child.callback.is_valid():
			child.callback.callv(child.params)
	
	elif child is VNTree.Choice:
		if child.option.attr_options.size() < 1:
			pass
		
		else:
			var p := PopupPanel.new()
			var v := VBoxContainer.new()
			var t := Label.new()
			t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t.text = child.option.attr_label
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_child(t)
		
			for option in child.option.attr_options:
				var op := Button.new()
				op.text = option.label
				
				var seen_key : String = child.option.attr_label + "::" + option.label
				if _seen_options.get(seen_key, false):
					op.modulate = Color(0.55, 0.55, 0.55)
				
				op.pressed.connect(func() -> void:
					_seen_options[seen_key] = true
					p.queue_free()
					option.callback.call())
				v.add_child(op)
			
			p.size = Vector2i(
				DisplayServer.window_get_size().x / 2,
				DisplayServer.window_get_size().y
			)
			p.always_on_top = true
			#p.exclusive = true
			p.transparent = true
			p.transparent_bg = true
			p.borderless = true
			p.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
			p.add_child(v)
			screen = p
			from.add_child(p)
			p.show()
			
			await p.tree_exited
	
	elif child is VNTree.Yield:
		if child.emit:
			unlock_context.emit()
		else:
			await unlock_context
	
	elif child is VNTree.Opacity:
		opacity_output = child.opacity
	
	elif child is VNTree.Enter:
		_do_enter(child.who, child.position, child.face_name)
	
	elif child is VNTree.Exit:
		_do_exit(child.position)
	
	elif child is VNTree.ShowBackground:
		_do_show_background(child.who, child.variant_name)
	
	elif child is VNTree.Goto:
		# A "chapter" script is a plain RefCounted with a build(s) method that
		# just calls s.says()/s.enter()/etc like any other script would. Those
		# calls go through register(), which appends to whatever list is
		# currently being walked (tree.root.childs, or layer_child.childs if
		# we're inside a layer) -- the SAME list this exec() call is already
		# iterating further down. So the new content gets picked up naturally
		# as soon as this Goto node's own (empty) turn is done; nothing here
		# needs to create a node, free a node, or swap a script.
		# Everything exec() walks is strictly forward -- by the time a NEW
		# goto fires, whatever the PREVIOUS builder registered has already
		# been fully walked and resolved (its choice already clicked, its
		# lines already shown), so it's safe to drop here rather than
		# holding every pass through a loop forever.
		_goto_builders.clear()
		
		# Don't carry leftover portraits from the previous script into the new one.
		for pos in PORTRAIT_POSITIONS:
			_do_exit(pos)
		
		var builder = child.target.new()
		_goto_builders.append(builder)
		if builder.has_method("build"):
			builder.build(self)
		else:
			push_warning("Scripted: goto target has no build(s) method.")
	
	for ch in child.childs:
		await exec(ch)
	
	return Error.OK

func start() -> void:
	await exec(tree.root)
	return
