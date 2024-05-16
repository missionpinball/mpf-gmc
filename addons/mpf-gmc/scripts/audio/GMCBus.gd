@tool
extends LoggingNode
class_name GMCBus

enum BusType { SOLO, SEQUENTIAL, SIMULTANEOUS }

var channels: Array[GMCChannel] = []
var type: BusType = BusType.SIMULTANEOUS
var queue
var duckings: Array[DuckSettings] = []
var _next_release: float

func _init(n: String):
	self.name = n
	self.configure_logging("Bus<%s>" % self.name)

func create_channel(channel_name: String) -> GMCChannel:
	var channel = GMCChannel.new(channel_name, self)
	self.channels.append(channel)
	return channel

func set_type(t: BusType):
	self.type = t
	# Sequential busses get a queue to store pending sounds
	if t == BusType.SEQUENTIAL:
		self.queue = []

func play(filename: String, settings: Dictionary = {}) -> void:
	self.log.info("play called for %s with settings %s" % [filename, settings])
	# Accept an absolute filepath too
	var filepath: String
	if filename.left(4) == "res:":
		filepath = filename
	else:
		# TODO: Clean this up now that sounds are indexed by MC
		filepath = "res://assets/%s/%s" % [self.name, filename]
	var available_channel: AudioStreamPlayer
	# REFACT:R is this needed?
	settings["bus"] = self.name

	# Clear out the queue if necessary, to free up channels
	if settings.get("clear_queue", false):
		self.clear_queue()

	# Check our channels to see if (1) one is empty or (2) one already has this
	else:
		available_channel = self._find_available_channel(filepath, settings)

	# If this is a solo bus, stop any other playback
	if self.type == BusType.SOLO:
		for c in self.channels:
			if c.playing and c != available_channel:
				# AVW Restore this after refactor
				pass
				#self._stop(c, settings)

	# If the available channel we got back is already playing, it's playing this file
	# and we don't need to do anything further.
	if available_channel and available_channel.playing:
		self.log.debug("Recevied available channel that's already playing, no-op.")
		return

	if not available_channel:
		# Queue the filename if this bus type has a queue
		if self.queue:
			# By default, max queue time is forever
			var max_queue_time: float = settings.get("max_queue_time", -1.0)
			if max_queue_time != 0:
				self.queue.append(self._generate_queue_item(filename, max_queue_time, settings))
		return
	if not available_channel.stream:
		available_channel.load_stream(filepath)
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
			# AVW Disabling this during refactor
			#channel.finished.connect(self._on_loop.bind(channel))
	# elif start_at == -1.0:
	# 	# Map the sound start position relative to the music position
	# 	start_at = fmod(_music_loop_channel.get_playback_position(), channel.stream.get_length())

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
	# if settings.get("ducking"):
	# 	duck_settings = settings.ducking
	# 	duck_settings.release_timestamp = channel.stream.get_length() - duck_settings.get("release_point", default_duck.release_point)
	# 	if duck_settings.get("delay"):
	# 		duckAttackTimer.start(duck_settings.delay)
	# 	else:
	# 		self._duck_attack()

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

# func duck(settings) -> void:
# 	if not settings is DuckSettings:
# 		settings = DuckSettings.new(settings)
# 	self.duckings.append(settings)
# 	self.duckings.sort_custom(
# 		func(a, b): return a.attenuation < b.attenuation
# 	)

func clear_queue() -> void:
	if not queue:
		return
	for q in queue:
		# Clear any streams from these channels so they can be available again
		if q.get("channel", false):
			q["channel"].stream = null
	# Remove all items from the queue
	queue.clear()


func _find_available_channel(filepath: String, settings: Dictionary) -> AudioStreamPlayer:
	var available_channel
	for channel in self.channels:
		if channel.stream and channel.stream.resource_path == filepath:
			# If this file is *already* playing, keep playing
			if channel.playing:
				# If this channel has a tween, override it
				if channel.has_meta("tween") and is_instance_valid(channel.get_meta("tween")):
					# Stop the tween
					var tween = channel.get_meta("tween")
					tween.stop_all()
					# AVW: DISABLING DURING REFACTOR
					#self._on_fade_complete(channel, tween,  "cancel")
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


static func get_bus_type(bus_string: String) -> BusType:
	return {
		"solo": BusType.SOLO,
		"sequential": BusType.SEQUENTIAL,
		"simultaneous": BusType.SIMULTANEOUS
	}.get(bus_string)
