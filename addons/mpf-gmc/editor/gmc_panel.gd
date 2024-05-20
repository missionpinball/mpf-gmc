@tool
extends GMCPanelBase


func _ready() -> void:
	config_section = "gmc"
	fields = [
		$main/flags/fullscreen,
		$main/global_logger/logging_global,
		$main/loggers/loggers_margin/loggers_list/sound_logger/logging_sound_player,
		$main/loggers/loggers_margin/loggers_list/bcp_logger/logging_bcp,
	]
	super()
	$main/show_all_toggle.toggled.connect(self._toggle_loggers)
	$main/show_all_toggle.button_pressed = false
	self._toggle_loggers(false)

func _toggle_loggers(toggled_on: bool) -> void:
	$main/loggers.visible = toggled_on
