# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

# Add this file as an Autoload in your Godot project for MPF-style logging.
# Override the log() method to change the output formatting.

extends RefCounted
class_name GMCLogger

enum LogLevel {
	USE_GLOBAL_LEVEL = -1,
	VERBOSE = 1,
	DEBUG = 10,
	INFO = 20,
	LOG = 25,
	WARNING = 30,
	ERROR = 40,
}

var _level: LogLevel = LogLevel.INFO
var _global_level: LogLevel = LogLevel.INFO
var log_name: String = ""

func _init(name: String = "", level: LogLevel = LogLevel.USE_GLOBAL_LEVEL, set_global: bool = false) -> void:
	self.log_name = "%s : " % name if name else ""
	self.setLevel(level)
	if set_global:
		_global_level = level

func setLevel(level: LogLevel) -> void:
	# GMC panel doesn't allow -1 as an index, so 0 counts as -1.
	if level <=0:
		level = _global_level
	_level = level

func getLevel() -> LogLevel:
	return _level

func verbose(message: String, args=null) -> void:
	if _level <= LogLevel.VERBOSE:
		print(GMCLogger._log(self.log_name, "VERBOSE", message, args))

func debug(message: String, args=null) -> void:
	if _level <= LogLevel.DEBUG:
		print(GMCLogger._log(self.log_name, "DEBUG", message, args))

func info(message: String, args=null) -> void:
	if _level <= LogLevel.INFO:
		print(GMCLogger._log(self.log_name, "INFO", message, args))

func log(message: String, args=null) -> void:
	if _level <= LogLevel.LOG:
		print(GMCLogger._log(self.log_name, "LOG", message, args))

func warning(message: String, args=null) -> void:
	if _level <= LogLevel.WARNING:
		print_rich("[color=yellow]%s[/color]" % GMCLogger._log(self.log_name, "WARNING", message, args))

func error(message: String, args=null) -> void:
	printerr(GMCLogger._log(self.log_name, "ERROR", message, args))

func fail(message: String, args=null) -> void:
	self.error(message, args)
	assert(false, message % args)

static func _log(l_name: String, level: String, message: String, args=null) -> String:
	# TODO: Incorporate ProjectSettings.get_setting("logging/file_logging/enable_file_logging")
	# Get datetime to dictionary
	var dt=Time.get_datetime_dict_from_system()
	# Format and print with message
	return "%02d:%02d:%02d.%03d : %s : %s%s" % [dt.hour,dt.minute,dt.second, int(Time.get_unix_time_from_system() * 1000) % 1000, level, l_name, message if args == null else (message % args)]
