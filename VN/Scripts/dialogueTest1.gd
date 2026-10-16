extends Node

var s := Scripted.new()
var akisa : VNChar

@export var text : RichTextLabel
@export var author : Label
@export var portrait_left : Control
@export var portrait_center : Control
@export var portrait_right : Control

func _init() -> void:
	s.from = self
	akisa = s.character().name("Akisa").color(Color("FFA5F1ff")).face_sheet(preload("res://VN/Images/Characters/Part 1/akisa.png"), Vector2i(195, 296))

func opt1() -> void:
	s.layer_init()
	s.says("This is the line for picking Option 1.")
	s.layer_start()
	s.resume()

func opt2() -> void:
	s.layer_init()
	s.says("This is the line for picking Option 2.")
	s.layer_start()
	s.resume()

func _ready() -> void:
	s.portrait_left = portrait_left
	s.portrait_center = portrait_center
	s.portrait_right = portrait_right
	s.says("Welcome to the Dialogue Showcase. This will test parts of the dialogue/visual novel system for C4GED: Containment Security.")
	akisa.says("This is a test of dialogue.")
	akisa.says("Notice the white-pink name \"Akisa\" somewhere onscreen. This is the current speaker.")
	s.says("This line has no speaker.")
	s.enter(akisa, "right", "")
	akisa.says("This is a test of showing a character. The input to say this line is put in after the input to show the character. The character has been placed in the \"Right\" slot.")
	s.exit("right")
	s.enter(akisa, "left", "")
	akisa.says("This is the \"Left\" slot.")
	s.exit("left")
	s.enter(akisa, "center", "")
	akisa.says("And this is the \"Center\" slot.")
	akisa.says("These slots are meant to be used to show characters that are visible to the character's eyes, or who's currently speaking.")
	s.choices("This is a choice prompt.").option("Option 1", opt1).option("Option 2", opt2)
	s.pause()
	akisa.says("That is the end of the current showcase.")
	akisa.says("Repeating script. . .")
	s.goto(preload("res://VN/Scripts/dialogue_scene.gd"))
	s.start()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		s.confirm.emit()
	
	var ch = s.get_character()
	text.text = s.text_output
	text.modulate.a = s.opacity_output
	text.visible_characters = text.get_total_character_count() - s.text_output.length() + int(s.vrat_output * s.text_output.length())
	
	author.text = ch.attr_name if ch != null else ""
	author.modulate = ch.attr_color if ch != null else Color.WHITE
	author.modulate.a = s.opacity_output
