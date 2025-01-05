extends LoggingNode

const CONFIG_PATH = "res://gmc.cfg"
const LOCAL_CONFIG_PATH = "user://gmc.local.cfg"
const MPF_MIN_VERSION = "0.80.0"

var game
var media
var player
var process
var server
var util
var keyboard: = {}
var config
var local_config

func _init():

	# Configure logging with the value from the config, if provided.
	# Otherwise will default to INFO for debug builds and LOG for production.
	var default_log_level = 20 if OS.has_feature("debug") else 25
	# Set the GMC level as global log level before instantiating other loggers
	self.configure_logging("GMC", default_log_level, true)

	var plugin_config = ConfigFile.new()
	var perr = plugin_config.load("res://addons/mpf-gmc/plugin.cfg")
	if perr != OK:
		self.log.error("Error loading GMC plugin file.")
	self.log.log("Initializing GMC version %s" % plugin_config.get_value("plugin", "version"))

	for cfg in [[CONFIG_PATH, "config"], [LOCAL_CONFIG_PATH, "local_config"]]:
		self[cfg[1]] = ConfigFile.new()
		var err = self[cfg[1]].load(cfg[0])
		if err == OK:
			if cfg[1] == "local_config":
				self.log.log("Found local GMC config override file: %s" % ProjectSettings.globalize_path(cfg[0]))
			else:
				self.log.log("Found GMC configuration file %s." % ProjectSettings.globalize_path(cfg[0]))
		if err != OK:
			# Error 7 is file not found, that's okay
			if err == ERR_FILE_NOT_FOUND:
				pass
			else:
				self.log.error("Error loading GMC config file '%s': %s" % [cfg[0], error_string(err)])

	# Now that configs are loaded, update the global log level
	var global_log_level = self.get_config_value("gmc", "logging_global", default_log_level)
	self.log.setLevel(global_log_level, true)

	# Any default script can be overridden with a custom one
	# This is done explicitly line-by-line for optimized preload and relative paths
	for s in [
			# Static utility functions first
			["util", preload("scripts/utilities.gd"), "GMCUtil"],
			# Log is needed for the rest
			["log", preload("scripts/log.gd"), "GMCLogger"],
			# Game should be loaded next
			["game", preload("scripts/mpf_game.gd"), "GMCGame"],
			# Server depends on Game, should be loaded after
			["server", preload("scripts/bcp_server.gd"), "GMCServer"],
			# Process is here too
			["process", preload("scripts/process.gd"), "GMCProcess"],
			# Media controller can come last
			["media", preload("scripts/media.gd"), "GMCMedia"]
	]:
		var script = self.get_config_value("gmc", s[2], false)
		# TODO: Add logging configuration as init parameters so logging
		# is available in the _init() methods of all scripts
		if script:
			self[s[0]] = load(script).new()
		else:
			self[s[0]] = s[1].new()
		# If an explicit value is set for this log, use it
		if self[s[0]] is LoggingNode:
			var script_log_level = self.get_config_value("gmc", "logging_%s" % s[0], -1)
			self[s[0]].configure_logging(s[2], script_log_level)

func _enter_tree():
	# self._process() is only called on children in the tree, so add the children
	# that need to call _process() or that have _enter_tree() methods. Also children
	# will be automatically freed on exit, so it's good to add them anyway.
	self.add_child(server)
	self.add_child(media)
	self.add_child(process)
	self.add_child(game)

func _ready():
	if self.config.has_section("keyboard"):
		for key in self.config.get_section_keys("keyboard"):
			keyboard[key.to_upper()] = self.get_config_value("keyboard", key)
	# Sound Player can have its own log level
	var sound_log_level = self.get_config_value("gmc", "logging_sound_player", self.log.getLevel())
	self.media.sound.initialize(self.config, sound_log_level)

func save_config():
	self.config.save(CONFIG_PATH)

func get_config_value(section: String, key: String, default = null) -> Variant:
	if self.has_local_config_value(section, key):
		return self.local_config.get_value(section, key)
	return self.config.get_value(section, key, default)

func get_config_keys(section: String) -> PackedStringArray:
	var result = PackedStringArray()
	if self.local_config.has_section(section):
		result.append_array(self.local_config.get_section_keys(section))
	if self.config.has_section(section):
		result.append_array(self.config.get_section_keys(section))
	return result

func has_config_section(section: String) -> bool:
	return self.local_config.has_section(section) or self.config.has_section(section)

func has_local_config_value(section: String, key: String) -> bool:
	return self.local_config.has_section_key(section, key)

func validate_min_version(compare_version: String) -> bool:
	return _explode_version_string(compare_version) >= _explode_version_string(MPF_MIN_VERSION)

func _explode_version_string(version: String) -> int:
	var bits = version.split(".")
	while bits.size() < 4:
		bits.append("0")
	bits[3] = bits[3].trim_prefix("dev")
	return int(bits[0]) * 1_000_000 + int(bits[1]) * 10_000 + int(bits[2]) * 100 + int(bits[3])

func _input(event: InputEvent) -> void:
	# Don't accept any non-keyboard input
	if not event.is_class("InputEventKey"):
		get_tree().get_root().set_input_as_handled()
		return

	# ALWAYS set the input as handled to prevent Godot default InputMap
	# from trying to manage UI. The only input that should propagate to
	# handlers is from BCP (which has key_label -1)
	if event.key_label != -1:
		get_tree().get_root().set_input_as_handled()
	else:
		return

	# Don't support holding down a key
	if event.is_echo():
		return

	var keycode = OS.get_keycode_string(event.get_key_label_with_modifiers()).to_upper()
	#print(keycode)
	if keycode == "ESCAPE" and self.get_config_value("gmc", "exit_on_esc", false):
		if not event.is_pressed():
			return
		# Cannot use quit() method because it won't cleanly shut down threads
		# Instead, send a notification to the main thread to shut down
		get_tree().notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
		return

	if keycode in keyboard:
		var cfg = keyboard[keycode]
		match cfg[0]:
			"event":
				# Only handle events on the press, not the release
				if not event.is_pressed():
					return
				# If a kwarg dict is provided, include it
				if cfg.size() > 2:
					MPF.server.send_event_with_args(cfg[1], cfg[2])
				else:
					MPF.server.send_event(cfg[1])
			"switch":
				var action
				var state
				if cfg.size() < 3:
					action = "active" if event.is_pressed() else "inactive"
				elif not event.is_pressed():
					return
				else:
					action = cfg[2]
				match action:
					"active":
						state = 1
					"inactive":
						state = 0
					"toggle":
						state = -1
				MPF.server.send_switch(cfg[1], state)
			_:
				return
