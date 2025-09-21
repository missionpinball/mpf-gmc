# Extensible class for configuring file-specific logging
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

class_name LoggingNode
extends Node

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger
const GLogger = preload("res://addons/mpf-gmc/scripts/log.gd")


func configure_logging(log_name: String = self.name, level: GLogger.LogLevel = GLogger.LogLevel.USE_GLOBAL_LEVEL, set_global: bool = false):
  self.log = GLogger.new(log_name, level, set_global)
