@tool
extends Control
class_name GMCPanelBase

var config_section = null
@onready var fields := []

func _ready() -> void:
	for child in fields:
		# Find an initial value
		var value
		if MPF.config.has_section_key(config_section, child.name):
			value = MPF.config.get_value(config_section, child.name)
		if child is TextEdit:
			if value != null:
				child.text = value
			child.text_changed.connect(self._set_dirty)
		elif child is CheckButton:
			if value != null:
				child.button_pressed = value
			child.pressed.connect(self._set_dirty)
		elif child is OptionButton:
			if value != null:
				self._set_option_button(child, value)
			child.item_selected.connect(self._set_dirty)

func _set_option_button(button: OptionButton, value: int) -> int:
	for i in range(0, button.item_count):
		if button.get_item_id(i) == value:
			button.select(i)
			return i
	return -1

func _set_dirty(_param = null) -> void:
	# By default, auto-save changes. Override if necessary.
	self._save()

func _save() -> void:
	for child in fields:
		if child is TextEdit:
			if child.text:
				MPF.config.set_value(config_section, child.name, child.text)
			elif MPF.config.has_section_key(config_section, child.name):
				MPF.config.erase_section_key(config_section, child.name)
		elif child is CheckButton:
			MPF.config.set_value(config_section, child.name, child.button_pressed)
		elif child is OptionButton:
			MPF.config.set_value(config_section, child.name,
				child.get_item_id(child.selected)
			)
	MPF.save_config()