@tool
extends Control

@onready var logLevelSelector = $VBoxContainer/LogLevel
@onready var config = ConfigFile.new()
var _config_path = "res://gmc.cfg"

func _ready() -> void:
	self.config.load(self._config_path)
	var initial_value = self.config.get_value("logging", "global", 20)
	for i in range(0, logLevelSelector.item_count):
		if logLevelSelector.get_item_id(i) == initial_value:
			logLevelSelector.select(i)
			break
	$VBoxContainer/LogLevel.item_selected.connect(self.set_log_level)

func set_log_level(index: int) -> void:
	var id = $VBoxContainer/LogLevel.get_item_id(index)
	self.config.set_value("logging", "global", id)
	self.config.save(self._config_path)