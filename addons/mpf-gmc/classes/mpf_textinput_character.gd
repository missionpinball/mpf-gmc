@tool
extends Label

const highlight_material = preload("res://addons/mpf-gmc/resources/textinput_highlight_material.tres")

var highlight_color := Color(1, 0, 0):
	set(value):
		highlight_color = value
		highlight_material.set_shader_parameter("highlight_color", value)

var grid_width: int = 0:
	set(value):
		grid_width = value
		self.custom_minimum_size.x = value
		self._on_rect_changed()

var is_special_char = false

func _init():
	self.item_rect_changed.connect(self._on_rect_changed)

func focus():
	self.material = highlight_material

func unfocus():
	self.material = null

func _on_rect_changed():
	if grid_width and self.size.x > grid_width:
		self.custom_minimum_size.x = grid_width * ceil(self.size.x / grid_width)
