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

func _set_dirty() -> void:
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
	MPF.save_config()