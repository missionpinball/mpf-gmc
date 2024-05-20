# Extensible class for configuring file-specific logging
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

class_name LoggingNode
extends Node

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger
const Logger = preload("res://addons/mpf-gmc/scripts/log.gd")


func configure_logging(log_name: String = self.name, level: Logger.LogLevel = Logger.LogLevel.USE_GLOBAL_LEVEL, set_global: bool = false):
  self.log = Logger.new(log_name, level, set_global)
