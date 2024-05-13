@tool

class_name MPFLogger
extends Node



const Logger = preload("res://addons/mpf-gmc/scripts/log.gd")

@export var log_level: Logger.LogLevel = Logger.LogLevel.USE_GLOBAL_LEVEL
@export var loggers: Array[Node]

# This is called on init so that logs in _enter_tree and _ready will be output.
# Therefore all child that set self.log as GMCLogger must also do so in init.
func _init():
	for n in self.loggers:
		if n.get("log") is GMCLogger:
			n.log.setLevel(self.log_level)