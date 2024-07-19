@tool
class_name MPFTextInput
extends HFlowContainer

const MPFTextInputChar = preload("res://addons/mpf-gmc/classes/mpf_textinput_character.gd")

## The list of characters to display in the text input
@export_multiline var allowed_characters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
## Allow spaces in input strings
@export var allow_space := true
## A fixed (minimum) width for each character displayed
@export var grid_width := 0:
	set(value):
		grid_width = value
		for c in self.get_children():
			c.grid_width = value
## Maximum number of characters allowed to be input
@export var max_length := 10

@export_group("Text Formatting")
## Color to highlight the selected text
@export var highlight_color := Color(1, 0, 1):
	set(value):
		highlight_color = value
		for c in self.get_children():
			c.highlight_color = value

func _enter_tree() -> void:
	for c in allowed_characters:
		var charact = self.generate_character(c)
		self.add_child(charact)
	if allow_space:
		var space = self.generate_character("SPACE")
		self.add_child(space)
	for s in ["DEL", "END"]:
		var special = self.generate_character(s)
		self.add_child(special)

func _ready() -> void:
	self.get_child(0).focus()

func generate_character(text):
	var charact = MPFTextInputChar.new()
	charact.text = text
	charact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charact.highlight_color = highlight_color
	if grid_width:
		charact.grid_width = grid_width
	return charact
