# Extensible class for configuring file-specific logging
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

class_name LoggingNode
extends Node

var logger: GMCLogger


func configure_logging(level: int = 0):
  self.logger = preload("res://addons/mpf-gmc/scripts/log.gd").new()
  self.logger.setLevel(level if level else MPF.log.getLevel())

func _exit_tree():
  self.logger.queue_free()
