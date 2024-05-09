# Extensible class for configuring file-specific logging
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

class_name LoggingNode
extends Node

@warning_ignore("native_method_override")
var log: GMCLogger
const Logger = preload("res://addons/mpf-gmc/scripts/log.gd")

@export var log_level: Logger.LogLevel = Logger.LogLevel.USE_GLOBAL_LEVEL

func configure_logging(log_name: String = self.name, level: Logger.LogLevel = self.log_level):
  self.log = Logger.new(log_name, level)
