@tool
extends Control
class_name GMCPanelBase

const CONFIG_PATH = "res://gmc.cfg"

var config: ConfigFile
var config_section = null
@onready var fields := []

func _init():
	self.config = ConfigFile.new()
	var err = self.config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		printerr("Error loading config file '%s': %s" % [CONFIG_PATH, error_string(err)])

func _ready() -> void:
	for child in fields:
		# Find an initial value
		var value
		if self.config.has_section_key(config_section, child.name):
			value = self.config.get_value(config_section, child.name)
		if child is TextEdit:
			child.text = value if value else ""
			child.text_changed.connect(self._set_dirty)
		elif child is CheckButton:
			child.button_pressed = value if value else false
			child.pressed.connect(self._set_dirty)
		elif child is OptionButton:
			if value != null:
				self._set_option_button(child, value)
			else:
				child.select(0)
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
	# Until we have a singleton in the editor, re-load the config
	# in case another panel has modified it
	var err = self.config.load(CONFIG_PATH)
	for child in fields:
		if child is TextEdit:
			if child.text:
				self.config.set_value(config_section, child.name, child.text)
			elif self.config.has_section_key(config_section, child.name):
				self.config.erase_section_key(config_section, child.name)
		elif child is CheckButton:
			self.config.set_value(config_section, child.name, child.button_pressed)
		elif child is OptionButton:
			self.config.set_value(config_section, child.name,
				child.get_item_id(child.selected)
			)
	self.config.save(CONFIG_PATH)