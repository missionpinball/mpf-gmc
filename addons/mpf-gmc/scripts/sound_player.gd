# Copyright 2021 Paradigm Tilt

extends LoggingNode

signal marker(event_name: String)

@onready var duckAttackTimer = Timer.new()
@onready var duckReleaseTimer = Timer.new()

var buses := {}
var default_bus: GMCBus
var default_duck_bus: GMCBus


func initialize(config: ConfigFile, log_level: int = 30) -> void:
	self.configure_logging("SoundPlayer")
	for i in range(0, AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		self.buses[bus_name] = GMCBus.new(bus_name, log_level)
		# Buses have tweens so must be in the tree
		self.add_child(self.buses[bus_name])
	if config.has_section("sound_system"):
		for key in config.get_section_keys("sound_system"):
			var settings: Dictionary = config.get_value("sound_system", key)
			var target_bus_name: String = settings['bus'] if settings.get('bus') else key
			assert(target_bus_name in self.buses, "Sound system does not have an audio bus '%s' configured." % target_bus_name)
			assert(settings.get("type"), "Sound system bus '%s' missing required field 'type'." % target_bus_name)
			var bus_type := GMCBus.get_bus_type(settings["type"])
			var bus: GMCBus = self.buses[target_bus_name]
			bus.set_type(bus_type)
			var channels_to_make = 2 if bus_type == GMCBus.BusType.SOLO else settings.get("simultaneous_sounds", 1)
			for i in range(0, channels_to_make):
				var channel_name: String = "%s_%s" % [target_bus_name, i+1]
				bus.create_channel(channel_name)
			# A bus can be marked default
			if settings.get("default", false):
				self.default_bus = self.buses[target_bus_name]
			# A bus can be default for ducking
			if settings.get("duck_default", false):
				self.default_duck_bus = self.buses[target_bus_name]

func _ready() -> void:
	MPF.game.volume.connect(self._on_volume)
	MPF.server.connect("clear", self._on_clear_context)
	# Set names to help debugging
	duckAttackTimer.name = "DuckAttackTimer"
	duckReleaseTimer.name = "DuckReleaseTimer"

func _exit_tree():
	duckAttackTimer.free()
	duckReleaseTimer.free()

func get_bus(bus_name: String = "") -> GMCBus:
	if not bus_name:
		assert(self.default_bus, "No default bus defined.")
		return self.default_bus
	return self.buses[bus_name]

func get_ducking_bus(bus_name: String = "") -> GMCBus:
	if not bus_name:
		assert(self.default_duck_bus, "No default duck bus defined.")
		return self.default_duck_bus
	return self.get_bus(bus_name)

func play_sounds(s: Dictionary) -> void:
	assert(typeof(s) == TYPE_DICTIONARY, "Sound player called with non-dict value: %s" % s)
	self.log.debug("play_sounds called with: %s", s)
	for asset in s.settings.keys():
		var settings: Dictionary = s.settings[asset]

		assert(MPF.media.sounds.has(asset), "Unknown sound file or resource '%s'" % asset)
		# A key can override the default value
		if not settings.get("key"):
			settings["key"] = asset

		var bus: GMCBus = self.buses[settings["bus"]] if settings.get("bus") else self.default_bus
		var action: String = settings.get("action", "play")

		# A key is all we need to stop
		if action == "stop" or action == "loop_stop":
			# TODO: Accept GMCBus as a stop param?
			bus.stop(settings.key, settings)
			return

		var config: Variant = MPF.media.get_sound_instance(asset)
		if not config:
			printerr("Unable to find sound instance for asset '%s'" % asset)
			return
		# If the result is a stream, there's no custom asset resource
		if config is AudioStream:
			settings["file"] = config.resource_path
		# If this sound is defined with a custom asset resource, populate those values
		elif config is MPFSoundAsset:
			assert(config.stream, "Sound asset %s is missing a Stream resource." % asset)
			settings["file"] = config.stream.resource_path
			for prop in [ "bus", "fade_in", "fade_out", "start_at", "max_queue_time"]:
				# Any values passed from the event have priority, only populate
				# asset property values not defined from the event.
				if settings.get(prop) == null and config.get(prop):
					settings[prop] = config[prop]
			# If the MPFSoundAsset has ducking, use that
			if config.ducking:
				# Create a new ducking that merges the settings (overwrites MPFSoundAsset)
				settings.ducking = DuckSettings.new(settings.get("ducking"), config.ducking)
			if config.markers:
				settings.markers = config.markers
		else:
			assert(false, "Cannot play sound of class %s" % config.get_class())

		var file: String = settings.get("file", asset)
		settings['context'] = settings.get("custom_context", s.context)

		if action == "replace":
			for channel in bus.channels:
				if channel.playing:
					channel.stop_with_settings()
		bus.play(file, settings)

func play_bus(s: Dictionary) -> void:
	for bus_name in s.settings.keys():
		assert(bus_name in self.buses, "Bus name %s is not a valid audio bus." % bus_name)
		var bus: GMCBus = self.buses[bus_name]
		var settings: Dictionary = s.settings[bus_name]

		match settings["action"]:
			"pause":
				bus.pause({"fade_out": settings.get("fade")})
			"unpause":
				bus.unpause({"fade_in": settings.get("fade")})
			"stop":
				bus.stop_all(settings.get("fade", 0.0))

# Not currently implemented anywhere
func stop_all(fade_out: float = 1.0) -> void:
	self.log.debug("STOP ALL called with fadeout of %s" , fade_out)
	for bus in self.buses.values():
		bus.stop_all(fade_out)

func _on_volume(bus: String, value: float, _change: float) -> void:
	var bus_name: String = bus.trim_suffix("_volume")
	# The Master bus is fixed and capitalized
	if bus_name.to_lower() == "master":
		bus_name = "Master"
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))
		return
	# Some devices, like hardware sound platforms, have volumes as well.
	# Those don't correspond to buses, so ignore them.
	if bus_name not in self.buses:
		self.log.debug("No software audio bus named '%s', ignoring.", bus_name)
		return
	self.buses[bus_name].set_bus_volume_full(linear_to_db(value))

func _on_clear_context(context_name: String) -> void:
	# Loop through all the channels and stop any that are playing this context
	for bus in self.buses.values():
		bus.clear_context(context_name)
