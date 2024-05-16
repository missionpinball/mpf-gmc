@tool
extends Control

@onready var logLevelSelector = $VBoxContainer/HBoxContainer/LogLevel

func _ready() -> void:
	var initial_value = MPF.config.get_value("logging", "global", 20)
	for i in range(0, logLevelSelector.item_count):
		if logLevelSelector.get_item_id(i) == initial_value:
			logLevelSelector.select(i)
			break
	logLevelSelector.item_selected.connect(self.set_log_level)

func set_log_level(index: int) -> void:
	var id = logLevelSelector.get_item_id(index)
	MPF.config.set_value("logging", "global", id)
	MPF.save_config()
