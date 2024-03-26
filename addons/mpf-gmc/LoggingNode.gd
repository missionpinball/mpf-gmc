# Extensible class for configuring file-specific logging
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

extends Node
class_name LoggingNode

var logger: Logger


func configure_logging(level: int = 0):
  self.logger = preload("res://addons/godot_bcp_server/log.gd").new()
  self.logger.setLevel(level if level else Log.getLevel())

func _exit_tree():
  self.logger.queue_free()
