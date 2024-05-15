@tool
extends LoggingNode
class_name GMC

const CONFIG_PATH = "res://gmc.cfg"

var game
var media
var player
var process
var server
var util
var keyboard: = {}
var config

func _init():
	self.config = ConfigFile.new()
	var err = self.config.load(CONFIG_PATH)
	if err != OK:
		printerr("Error loading config file: %s" % err)
	# Configure logging with the value from the config
	var global_log_level = self.config.get_value("logging", "global", 30)

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
		var script = self.config.get_value("gmc", s[2], false)
		# TODO: Add logging configuration as init parameters so logging
		# is available in the _init() methods of all scripts
		if script:
			self[s[0]] = load(script).new()
		else:
			self[s[0]] = s[1].new()
		# If an explicit value is set for this log, use it
		if self[s[0]] is LoggingNode:
			var script_log_level = self.config.get_value("logging", s[0], -1)
			if script_log_level == -1:
				script_log_level = global_log_level
			self[s[0]].configure_logging(s[2], script_log_level)

	self.configure_logging("GMC", global_log_level)


func _enter_tree():
	# self._process() is only called on children in the tree, so add the children
	# that need to call _process() or that have _enter_tree() methods
	self.add_child(server)
	self.add_child(media)
	self.add_child(process)

func _ready():
	if self.config.has_section("keyboard"):
		for key in self.config.get_section_keys("keyboard"):
			keyboard[key.to_upper()] = self.config.get_value("keyboard", key)
	self.media.sound.initialize(self.config)

func save_config():
	self.config.save(CONFIG_PATH)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_class("InputEventKey"):
		return
	# Don't support holding down a key
	if event.is_echo():
		return
	var keycode = OS.get_keycode_string(event.get_key_label_with_modifiers()).to_upper()
	#print(keycode)
	if keycode == "ESCAPE":
		# Cannot use quit() method because it won't cleanly shut down threads
		# Instead, send a notification to the main thread to shut down
		#get_tree().notification(NOTIFICATION_WM_CLOSE_REQUEST)
		# get_tree().quit()
		return

	if keycode in keyboard:
		var cfg = keyboard[keycode]
		match cfg[0]:
			"event":
				# Only handle events on the press, not the release
				if not event.is_pressed():
					return
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
		get_tree().get_root().set_input_as_handled()
