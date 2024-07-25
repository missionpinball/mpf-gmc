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
		# Reset the min width
		self.custom_minimum_size.x = 0
		self._on_rect_changed()

var is_special_char = false
var _natural_width := 0.0

func _init():
	self.item_rect_changed.connect(self._on_rect_changed)
	self.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _enter_tree():
	# Save the natural width so we can recalculate new grid sizes
	_natural_width = self.size.x
	self._on_rect_changed()

func focus():
	self.material = highlight_material

func unfocus():
	self.material = null

func _on_rect_changed():
	# Wait for the natural width to be calculated
	if not grid_width or not _natural_width:
		self.custom_minimum_size.x = 0
		return
	if _natural_width > grid_width:
		@warning_ignore("integer_division")
		self.custom_minimum_size.x = grid_width * ceil(_natural_width / grid_width)
	else:
		self.custom_minimum_size.x = grid_width
