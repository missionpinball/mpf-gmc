@tool
extends Control

const CONFIG_SECTION = "mpf"

@onready var fields := [
	$main/executable_path,
	$main/executable_args,
	$main/mpf_args,
	$main/flags/virtual,
]

func _ready() -> void:
	for child in fields:
		# Find an initial value
		var value
		if MPF.config.has_section_key(CONFIG_SECTION, child.name):
			value = MPF.config.get_value(CONFIG_SECTION, child.name)
		if child is TextEdit:
			if value != null:
				child.text = value
			child.text_changed.connect(self._set_dirty)
		elif child is CheckButton:
			if value != null:
				child.button_pressed = value
			child.pressed.connect(self._set_dirty)

	# Set a placeholder for the machine path
	if not $main/machine_path.text:
		$main/machine_path.placeholder_text = ProjectSettings.globalize_path("res://")
	# Always auto-save toggling the enable state
	$main/enable/spawn_mpf.toggled.connect(self._enable_toggled)

	# Use a built-in texture
	var theme = EditorInterface.get_editor_theme()
	$main/enable/spawn_error.texture = theme.get_icon("StatusWarning", "EditorIcons")
	self._set_enable_available()

	$main/buttons/save.disabled = true
	$main/buttons/save.pressed.connect(self._save)

func _enable_toggled(toggled_on: bool) -> void:
	MPF.config.set_value(CONFIG_SECTION, "spawn_mpf", toggled_on)
	MPF.save_config()

func _set_dirty() -> void:
	$main/buttons/save.disabled = false

func _set_enable_available():
	# If no path is set, show an alert icon
	if MPF.config.get_value(CONFIG_SECTION, "executable_path", ""):
		$main/enable/spawn_mpf.show()
		$main/enable/spawn_error.hide()
		$main/enable/spawn_mpf.disabled = false
		$main/enable/spawn_mpf.button_pressed = MPF.config.get_value(CONFIG_SECTION, "spawn_mpf", false)
	else:
		$main/enable/spawn_mpf.hide()
		$main/enable/spawn_error.show()
		$main/enable/spawn_mpf.disabled = true
		# If the config is saved as enabled, toggling the button will auto-save
		$main/enable/spawn_mpf.button_pressed = false

func _save() -> void:
	for child in fields:
		if child is TextEdit:
			if child.text:
				MPF.config.set_value(CONFIG_SECTION, child.name, child.text)
			elif MPF.config.has_section_key(CONFIG_SECTION, child.name):
				MPF.config.erase_section_key(CONFIG_SECTION, child.name)
		elif child is CheckButton:
			MPF.config.set_value(CONFIG_SECTION, child.name, child.button_pressed)
	MPF.save_config()
	$main/buttons/save.disabled = true
	self._set_enable_available()
