@tool
extends GMCPanelBase


func _ready() -> void:
	config_section = "gmc"
	fields = [
		$main/flags_top/fullscreen,
		$main/flags_bottom/exit_on_esc,
		$main/global_logger/logging_global,
		$main/loggers/loggers_margin/loggers_list/server_logger/logging_server,
		$main/loggers/loggers_margin/loggers_list/game_logger/logging_game,
		$main/loggers/loggers_margin/loggers_list/media_logger/logging_media,
		$main/loggers/loggers_margin/loggers_list/process_logger/logging_process,
		$main/loggers/loggers_margin/loggers_list/sound_logger/logging_sound_player,
	]
	super()
	$main/show_all_toggle.toggled.connect(self._toggle_loggers)
	$main/show_all_toggle.button_pressed = false
	self._toggle_loggers(false)

func _toggle_loggers(toggled_on: bool) -> void:
	$main/loggers.visible = toggled_on
