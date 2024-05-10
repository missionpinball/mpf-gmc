# Copyright 2021 Paradigm Tilt

@tool
extends LoggingNode

@onready var duckAttackTimer = Timer.new()
@onready var duckReleaseTimer = Timer.new()
var musicDuck: Tween

var busses = {}
var tweens = []
var default_bus: String

var _music_loop_channel: AudioStreamPlayer

# Counter for the current loop number of the music (zero-indexed)
# var _music_loops: int = 0
# Counter for what the next loop number will be
# var _music_loop_pending: int = 0

var duck_attenuation := 8
var duck_attack := 0.5
var duck_release := 0.5
var duck_settings
# TODO: Make this dynamically find the music/duck target bus
var unduck_level: float = AudioServer.get_bus_volume_db(1)

# TODO: Remove default duck, or make customizable/optional
const default_duck = {
	"delay": 0.0,
	"attack": 0.4,
	"attenuation": 8,
	"release_point": 0.3,
	"release": 0.6
}

func initialize(config: ConfigFile) -> void:
	self.configure_logging("SoundPlayer")
	for i in range(0, AudioServer.bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		self.busses[bus_name] = { "name": bus_name, "channels": [] }
	if config.has_section("sound_system"):
		for key in config.get_section_keys("sound_system"):
			var settings = config.get_value("sound_system", key)
			var target_bus = settings['bus'] if settings.get('bus') else key
			assert(target_bus in self.busses, "Sound system does not have an audio bus '%s' configured." % target_bus)
			assert(settings.get("type"), "Sound system bus '%s' missing required field 'type'." % target_bus)
			var bus_type = settings["type"]
			self.busses[target_bus]["type"] = bus_type
			var channels_to_make = 2 if bus_type == "solo" else settings.get("simultaneous_sounds", 1)
			for i in range(0, channels_to_make):
				var channel = AudioStreamPlayer.new()
				channel.name = "%s_%s" % [target_bus, i+1]
				self.busses[target_bus].channels.append(channel)
				self.add_child(channel)
				if bus_type == "sequential":
					channel.finished.connect(self._on_queue_channel_finished.bind(target_bus))
			# Sequential busses get a queue to store pending sounds
			if bus_type == "sequential":
				self.busses[target_bus]["queue"] = []
			# A bus can be marked default
			if settings.get("default", false):
				self.default_bus = target_bus

func _ready() -> void:
	duckAttackTimer.one_shot = true
	duckAttackTimer.timeout.connect(self._duck_attack)
	duckReleaseTimer.one_shot = true
	duckReleaseTimer.timeout.connect(self._duck_release)
	MPF.game.volume.connect(self._on_volume)
	MPF.server.connect("clear", self._on_clear_context)

func play_sounds(s: Dictionary) -> void:
	assert(typeof(s) == TYPE_DICTIONARY, "Sound player called with non-dict value: %s" % s)
	self.log.debug("play_sounds called with: %s" % s)
	for asset in s.settings.keys():
		var settings = s.settings[asset]

		assert(MPF.media.sounds.has(asset), "Unknown sound file or resource '%s'" % asset)

		var config = MPF.media.get_sound_instance(asset)
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
		else:
			assert(false, "Cannot play sound of class %s" % config.get_class())

		var bus: String = settings["bus"] if settings.get("bus") else self.default_bus
		var file: String = settings.get("file", asset)
		var action: String = settings.get("action", "play")
		settings['context'] = settings.get("custom_context", s.context)

		if action == "stop" or action == "loop_stop":
			self.stop(file, bus, settings)
			return
		if action == "replace":
			for channel in self._get_channels(bus):
				if channel.playing:
					self._stop(channel)
		self.play(file, bus, settings)

func play(filename: String, bus: String, settings: Dictionary = {}) -> void:
	self.log.info("play called for %s on bus %s with settings %s" % [filename, bus, settings])
	# Accept an absolute filepath too
	var filepath: String
	if filename.left(4) == "res:":
		filepath = filename
	else:
		# TODO: Clean this up now that sounds are indexed by MC
		filepath = "res://assets/%s/%s" % [bus, filename]
	var available_channel: AudioStreamPlayer
	settings["bus"] = bus

	# Clear out the queue if necessary, to free up channels
	if settings.get("clear_queue", false):
		self.clear_queue(bus)

	# Check our channels to see if (1) one is empty or (2) one already has this
	else:
		available_channel = self._find_available_channel(bus, filepath, settings)

	# If this is a solo bus, stop any other playback
	if self.busses[bus].type == "solo":
		for c in self._get_channels(bus):
			if c.playing and c != available_channel:
				self._stop(c, settings)

	# If the available channel we got back is already playing, it's playing this file
	# and we don't need to do anything further.
	if available_channel and available_channel.playing:
		self.log.debug("Recevied available channel that's already playing, no-op.")
		return

	if not available_channel:
		# Queue the filename if this bus type has a queue
		var target_queue = self.busses[bus].get("queue", null)
		if target_queue != null:
			# By default, max queue time is forever
			var max_queue_time: float = settings.get("max_queue_time", -1.0)
			if max_queue_time != 0:
				target_queue.append(self._generate_queue_item(filename, max_queue_time, settings))
		return
	if not available_channel.stream:
		available_channel.stream = self._load_stream(filepath)
	if not available_channel.stream:
		self.log.error("Failed to load stream for filepath '%s' on channel %s", [filepath, available_channel])
		return
	self._play(available_channel, settings)

func _play(channel: AudioStreamPlayer, settings: Dictionary) -> void:
	if not channel.stream:
		self.log.error("Attempting to play on channel %s with no stream. %s ", [channel, settings])
		return

	self.log.debug("playing %s (%s) on %s with settings %s", [channel.stream.resource_path, channel.stream, channel, settings])
	channel.stream.set_meta("context", settings.context)
	var start_at: float = settings["start_at"] if settings.get("start_at") else 0.0
	var fade_in: float = settings["fade_in"] if settings.get("fade_in") else 0.0
	if settings.get("fade_out"):
		channel.stream.set_meta("fade_out", settings.fade_out)

	if settings.get("loops"):
		# OGG and MPF use the 'loop' property, while WAV uses 'loop_mode
		if channel.stream is AudioStreamWAV:
			channel.stream.loop_mode = 1 if settings["loops"] != 0 else 0
		else:
			channel.stream.loop = settings["loops"] != 0
		# Attach metadata to track the loops
		if settings["loops"] > 0:
			channel.stream.set_meta("loops_remaining", settings["loops"])
			channel.finished.connect(self._on_loop.bind(channel))
	elif start_at == -1.0:
		# Map the sound start position relative to the music position
		start_at = fmod(_music_loop_channel.get_playback_position(), channel.stream.get_length())

	# TODO: Support marker events
	if settings.get("events_when_started"):
		for e in settings["events_when_started"]:
			MPF.server.send_event(e)
	if settings.get("events_when_stopped"):
		# Store a reference to the callable so it can be disconnected
		var callable = self._trigger_events.bind("stopped", settings["events_when_stopped"], channel)
		channel.stream.set_meta("events_when_stopped", callable)
		channel.finished.connect(callable)

	# If this is a voice or callout, duck the music
	if settings.get("ducking"):
		duck_settings = settings.ducking
		duck_settings.release_timestamp = channel.stream.get_length() - duck_settings.get("release_point", default_duck.release_point)
		if duck_settings.get("delay"):
			duckAttackTimer.start(duck_settings.delay)
		else:
			self._duck_attack()

	# If the current volume is less than the target volume, e.g. this was fading out
	# but was re-played, force a quick fade to avoid jumping back to full
	if not fade_in and channel.playing and channel.volume_db < 0:
		fade_in = 0.5
	if not fade_in:
		# Ensure full volume in case it was tweened out previously
		channel.volume_db = settings["volume"] if settings.get("volume") else 0.0
		channel.play(start_at)
		return
	# Set the channel volume and begin playing
	if not channel.playing:
		channel.volume_db = -80.0
		channel.play(start_at)
	var tween = self.create_tween()
	tween.tween_property(channel, "volume_db", 0.0, fade_in).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.finished.connect(self._on_fade_complete.bind(channel, tween, "play"))
	self.tweens.append(tween)
	channel.set_meta("tween", tween)

func stop(filename: String, bus: String, settings: Dictionary) -> void:
	var filepath: String
	# TODO: Track the stop by key, not filename
	if filename.left(4) == "res:":
		filepath = filename
	else:
		filepath = "res://assets/%s/%s" % [bus, filename]
	# Find the channel playing this file
	for channel in self._get_channels(bus):
		if channel.stream and channel.stream.resource_path == filepath and channel.playing and not channel.get_meta("is_stopping", false):
			self._stop(channel, settings)
			return
	# It's possible that the stop was called just for safety.
	# If no channel is found with this file, that's okay.


func _stop(channel: AudioStreamPlayer, settings: Dictionary = {}, action: String = "stop") -> void:
	if settings.get("action") == "loop_stop":
		# The position is reset when the loop mode changes, so store it first
		var pos: float = channel.get_playback_position()
		channel.stream.loop_mode = 0
		# Play the sound to the end of the file
		channel.play(pos)
		return
	var fade_out = settings.get("fade_out")
	if not fade_out and channel.stream.has_meta("fade_out"):
		fade_out = channel.stream.get_meta("fade_out")
	if not fade_out:
		self._clear_channel(channel)
		return
	var tween = self.create_tween()
	tween.tween_property(channel, "volume_db", -80.0, fade_out) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.finished.connect(self._on_fade_complete.bind(channel, tween, action))
	self.tweens.append(tween)
	channel.set_meta("tween", tween)
	channel.set_meta("is_stopping", true)

func stop_all(fade_out: float = 1.0) -> void:
	self.log.debug("STOP ALL called with fadeout of %s" , fade_out)
	duck_settings = null
	var tween = self.create_tween() if fade_out > 0 else null
	for bus_name in self.busses.keys():
		# Clear any queued buses as well, lest they be triggered after the stop
		self.clear_queue(bus_name)
		for channel in self.busses[bus_name].channels:
			if channel.playing and not channel.get_meta("is_stopping", false):
				if tween:
					tween.tween_property(channel, "volume_db", -80.0, fade_out) \
						.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
					channel.set_meta("is_stopping", true)
				else:
					self._clear_channel(channel)
	if tween:
		tween.finished.connect(self._on_fade_complete.bind(null, tween, "stop_all"))
		self.tweens.append(tween)
		tween.start()
	else:
		for t in self.tweens:
			t.stop()
		self.tweens = []

func clear_queue(bus: String) -> void:
	var queue_to_clear = self.busses[bus].get("queue")
	if not queue_to_clear:
		self.log.error("Bus '%s' does not have a queue to clear.", bus)
		return
	for q in queue_to_clear:
		# Clear any streams from these channels so they can be available again
		if q.get("channel", false):
			q["channel"].stream = null
	# Remove all items from the queue
	queue_to_clear.clear()

func _on_fade_complete(channel, tween, action) -> void:
	self.tweens.erase(tween)
	# If this is a stop_all action, finish all the channels that are stopping
	if action == "stop_all":
		for bus in self.busses.values():
			for c in bus.channels:
				if c.stream and c.get_meta("is_stopping", false):
					self._clear_channel(channel)
	# If this is a stop action, stop the channel
	elif action == "stop" or action == "clear":
		self.log.debug("Fade out complete on channel %s" % channel)
		self._clear_channel(channel)
	elif action == "play":
		self.log.debug("Fade in to %0.2f complete on channel %s", [channel.volume_db, channel])
	if action == "clear":
		channel.stream = null

func _on_loop(channel) -> void:
	var loops_remaining = channel.stream.get_meta("loops_remaining") - 1
	if loops_remaining == 0:
		channel.stream.remove_meta("loops_remaining")
		channel.finished.disconnect(self._on_loop)
		if channel.stream is AudioStreamWAV:
			channel.stream.loop_mode = 0
		else:
			channel.loop = false
	else:
		channel.stream.set_meta("loops_remaining", loops_remaining)


func _trigger_events(state, events, channel) -> void:
	for e in events:
		MPF.server.send_event(e)
	channel.finished.disconnect(channel.stream.get_meta("events_when_%s" % state))
	channel.stream.remove_meta("events_when_%s" % state)

func _get_channels(bus: String):
	if bus not in self.busses:
		self.log.error("Invalid bus %s requested", bus)
	return self.busses[bus].channels

func _clear_channel(channel):
	if channel.stream and channel.stream.has_meta("loops_remaining"):
		channel.finished.disconnect(self._on_loop)
		channel.stream.remove_meta("loops_remaining")
	channel.stop()
	channel.volume_db = 0.0
	channel.remove_meta("tween")
	channel.remove_meta("is_stopping")
	channel.stream = null

func _find_available_channel(bus: String, filepath: String, settings: Dictionary) -> AudioStreamPlayer:
	var available_channel
	for channel in self._get_channels(bus):
		if channel.stream and channel.stream.resource_path == filepath:
			# If this file is *already* playing, keep playing
			if channel.playing:
				# If this channel has a tween, override it
				if channel.has_meta("tween") and is_instance_valid(channel.get_meta("tween")):
					# Stop the tween
					var tween = channel.get_meta("tween")
					tween.stop_all()
					self._on_fade_complete(channel, tween,  "cancel")
				# If the channel does not have a tween, let it continue playing
				else:
					# If there is an explicit start time, jump there unless told otherwise
					if settings.get("start_at") != null and not settings.get("keep_position", false):
						channel.seek(settings["start_at"])
			self.log.debug("Channel %s already has resource %s, playing from memory", [channel, filepath])
			available_channel = channel
		elif not available_channel:
			if not channel.stream:
				self.log.debug("Channel %s has no stream, making it the available channel" % channel)
				available_channel = channel
			elif not channel.playing:
				self.log.debug("Channel %s has a stream %s but it's not playing, making it available" % [channel, channel.stream])
				available_channel = channel
				available_channel.stream = null
	return available_channel

func _generate_queue_item(filename: String, max_queue_time: float, settings: Dictionary) -> Dictionary:
	# Negative queue means infinite queue
	var expiration = INF if max_queue_time < 0 else (Time.get_ticks_msec() + (1000 * max_queue_time))
	return {
		"filename": filename,
		"expiration": expiration,
		"settings": settings
	}

func _on_queue_channel_finished(bus_name: String) -> void:
	# The two queues hold dictionary objects like this:
	#{ "filename": filename, "expiration": some_time, "settings": settings }
	var now := Time.get_ticks_msec()
	var queue = self.busses[bus_name].queue
	# Find the first item in the queue that's not expired
	while queue:
		var q_item: Dictionary = queue.pop_front()
		if q_item.expiration > now:
			self.play(q_item.filename, bus_name, q_item.settings)
			return

func _on_volume(bus: String, value: float, _change: float):
	var bus_name: String = bus.trim_suffix("_volume")
	# The Master bus is fixed and capitalized
	if bus_name == "master":
		bus_name = "Master"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func get_current_sound(bus: String) -> String:
	var channels = self._get_channels(bus)
	for channel in channels:
		if channel.playing:
			return channel.stream.resource_path.split("/")[-1]
	return ""

func is_resource_playing(bus: String, filepath: String) -> bool:
	var channels = self._get_channels(bus)
	for channel in channels:
		if channel.playing and channel.stream.resource_path == filepath:
			return true
	return false

func _duck_music(value: float):
	AudioServer.set_bus_volume_db(1, value)

func _duck_attack() -> void:
	if not duck_settings:
		return
	# We only have one duck at a time, so store the return values globally
	duck_release = duck_settings.get("release", default_duck.release)
	musicDuck = self.create_tween()
	musicDuck.tween_method(self._duck_music,
		# Always use the current level in case we're interrupting
		AudioServer.get_bus_volume_db(1),
		self.unduck_level - duck_settings.get("attenuation", default_duck.attenuation),
		duck_settings.get("attack", default_duck.attack),
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	self.log.debug("Ducking voice clip down with settings: %s", duck_settings)
	duckReleaseTimer.start(duck_settings.release_timestamp)


func _duck_release():
	if not duck_settings:
		return
	# If the music is ducked, unduck it
	if AudioServer.get_bus_volume_db(1) < self.unduck_level:
		self.log.debug("Unducking voice clip back to %0.2f db over %0.2f seconds", [self.unduck_level, duck_release])
		musicDuck.kill()
		musicDuck = self.create_tween()
		musicDuck.tween_method(self._duck_music,
			AudioServer.get_bus_volume_db(1),
			self.unduck_level,
			duck_release
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func _load_stream(filepath: String) -> AudioStream:
	return ResourceLoader.load(filepath, "AudioStreamOGGVorbis" if filepath.get_extension() == "ogg" else "AudioStreamSample") as AudioStream

func _on_clear_context(context_name: String) -> void:
	# Loop through all the channels and stop any that are playing this context
	for bus in self.busses.values():
		for channel in bus.channels:
			if channel.stream and channel.stream.has_meta("context") and \
			channel.stream.get_meta("context") == context_name and \
			channel.playing and not channel.get_meta("is_stopping", false):
				self._stop(channel)
