@tool
extends GMCPanelBase

func _ready() -> void:
	config_section = "mpf"
	fields = [
		$main/ScrollContainer/scroll_contents/executable_path,
		$main/ScrollContainer/scroll_contents/executable_args,
		$main/ScrollContainer/scroll_contents/machine_path,
		$main/ScrollContainer/scroll_contents/mpf_args,
		$main/ScrollContainer/scroll_contents/flags/virtual,
		$main/ScrollContainer/scroll_contents/flags/verbose,
	]
	super()
	# Set a placeholder for the machine path
	$main/ScrollContainer/scroll_contents/machine_path.placeholder_text = ProjectSettings.globalize_path("res://")
	# Always auto-save toggling the enable state
	$main/enable/spawn_mpf.toggled.connect(self._enable_toggled)

	# Use a built-in texture
	var theme = EditorInterface.get_editor_theme()
	$main/enable/spawn_error.texture = theme.get_icon("StatusWarning", "EditorIcons")
	self._set_enable_available()

	$main/buttons/save.disabled = true
	$main/buttons/save.pressed.connect(self._save)

func _enable_toggled(toggled_on: bool) -> void:
	MPF.config.set_value(config_section, "spawn_mpf", toggled_on)
	MPF.save_config()

func _set_dirty(_param = null) -> void:
	$main/buttons/save.disabled = false

func _set_enable_available():
	# If no path is set, show an alert icon
	if MPF.config.get_value(config_section, "executable_path", ""):
		$main/enable/spawn_mpf.show()
		$main/enable/spawn_error.hide()
		$main/enable/spawn_mpf.disabled = false
		$main/enable/spawn_mpf.button_pressed = MPF.config.get_value(config_section, "spawn_mpf", false)
	else:
		$main/enable/spawn_mpf.hide()
		$main/enable/spawn_error.show()
		$main/enable/spawn_mpf.disabled = true
		# If the config is saved as enabled, toggling the button will auto-save
		$main/enable/spawn_mpf.button_pressed = false

func _save() -> void:
	super()
	$main/buttons/save.disabled = true
	self._set_enable_available()
