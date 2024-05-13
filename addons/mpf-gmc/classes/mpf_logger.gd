@tool
class_name MPFLogger
extends Node

const LogLevel = preload("res://addons/mpf-gmc/scripts/log.gd").LogLevel

@export var log_level: LogLevel = LogLevel.USE_GLOBAL_LEVEL
@export var loggers: Array[Node]:
	set(value): self._set_loggers(value)


# This is called on set() so that logs in _enter_tree and _ready will be output.
# Therefore all child that set self.log as GMCLogger must do so in _init().
func _set_loggers(value: Array[Node] = []):
	# self.loggers = value
	if not value:
		return
	for n in value:
		if n.get("log") is GMCLogger:
			n.log.setLevel(self.log_level)
		else:
			printerr("Node %s does not have a log property of type GMCLogger" % n)
