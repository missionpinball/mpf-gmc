@tool
class_name MPFTextInput
extends HFlowContainer

const MPFTextInputChar = preload("res://addons/mpf-gmc/classes/mpf_textinput_character.gd")

signal text_changed(new_value)
var selected_index: int = -1
var current_text: String = ""

## The name of this text input for MPF event handling
@export var input_name: String = "high_score"

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
## Label node to display the current text selection
@export var display_node: Control
## If true, the currently highlighted character will be added to the preview
@export var preview_character: bool = true

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
		var space = self.generate_character("SPACE", true)
		self.add_child(space)
	for s in ["DEL", "END"]:
		var special = self.generate_character(s, true)
		self.add_child(special)

func _ready() -> void:
	# self.get_child(selected_index).focus()
	if not Engine.is_editor_hint():
		MPF.server.connect("text_input", self._on_text_input_event)
	# Trigger the movement to select the first character and
	# Preview the initial character that's focused
	self._on_move_input()

func generate_character(text: String, is_special_char:=false) -> MPFTextInputChar:
	var charact = MPFTextInputChar.new()
	charact.text = text
	charact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charact.highlight_color = highlight_color
	charact.is_special_char = is_special_char
	if grid_width:
		charact.grid_width = grid_width
	return charact

func _on_text_input_event(payload):
	match payload.action:
		"left":
			self._on_move_input(true)
		"right":
			self._on_move_input()
		"select":
			self._on_select()

func _on_select():
	var selection = self.get_child(selected_index)
	match selection.text:
		"SPACE":
			current_text += " "
		"DEL":
			current_text = current_text.left(-1)
		"END":
			MPF.server.send_event("text_input_%s_complete&text=%s" % [self.input_name, self.current_text.strip_edges()])
			return
		_:
			current_text += selection.text
	self.text_changed.emit(current_text)
	self._update_preview("" if selection.is_special_char else selection.text)


func _on_move_input(reverse:=false) -> void:
	self.get_child(selected_index).unfocus()
	selected_index += -1 if reverse else 1
	if selected_index < 0:
		selected_index = self.get_child_count() - 1
	elif selected_index >= self.get_child_count():
		selected_index = 0
	var new_selection = self.get_child(selected_index)
	new_selection.focus()
	if preview_character:
		self._update_preview("" if new_selection.is_special_char else new_selection.text)

func _update_preview(preview_char=""):
	if not display_node:
		return
	var text: String
	if preview_char and display_node is RichTextLabel:
		text = "%s[pulse freq=3.0 color=#%s ease=-1.0]%s[/pulse]" % [current_text, highlight_color.to_html(), preview_char]
	else:
		text = current_text + preview_char
	# Use the set_text method so custom nodes can handle it how they like
	display_node.set_text(text)
