# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

# Add this file as an Autoload in your Godot project for MPF-style logging.
# Override the log() method to change the output formatting.

extends Node
class_name Logger


var VERBOSE := 1
var DEBUG := 10
var INFO := 20
var WARN := 30

var _level: int = INFO
var log_name: String = ""

func _init(name: String = "", level: int = INFO) -> void:
  self.log_name = "<%s> " % name if name else ""
  self._level = level

func setLevel(level: int) -> void:
  _level = level

func getLevel() -> int:
  return _level

func verbose(message: String, args=null) -> void:
  if _level <= VERBOSE:
    print(self._log("[VERBOSE]", message, args))

func debug(message: String, args=null) -> void:
  if _level <= DEBUG:
    print(self._log("[DEBUG]", message, args))

func info(message: String, args=null) -> void:
  if _level <= INFO:
    print(self._log("[INFO]", message, args))

func warn(message: String, args=null) -> void:
  if _level <= WARN:
    push_warning(self._log("[WARN]", message, args))

func error(message: String, args=null) -> void:
  push_error(self._log("[ERROR]", message, args))

func fail(message: String, args=null) -> void:
  self.error(message, args)
  assert(false, message % args)

func _log(level: String, message: String, args=null) -> String:
  # TODO: Incorporate ProjectSettings.get_setting("logging/file_logging/enable_file_logging")
  # Get datetime to dictionary
  var dt=Time.get_datetime_dict_from_system()
  # Format and print with message
  return "%s %02d:%02d:%02d.%03d %s%s" % [level, dt.hour,dt.minute,dt.second, int(Time.get_unix_time_from_system() * 1000) % 1000, log_name, message if args == null else (message % args)]
