@tool
extends LoggingNode
class_name GMCBus

enum BusType { SOLO, SEQUENTIAL, SIMULTANEOUS }

var channels: Array[GMCChannel] = []
var type: BusType = BusType.SIMULTANEOUS
var queue
var duckings: Array[DuckSettings] = []
var _next_release: float
var _full_volume_db: float
var _bus_index: int
var _active_duck: Tween
var _duck_release_timer: Timer

func _init(n: String):
	self.name = n
	self.configure_logging("Bus<%s>" % self.name)
	# Store the target restore volume for post-ducks
	self._bus_index = AudioServer.get_bus_index(self.name)
	assert(self._bus_index != -1, "No audio bus %s configured in Godot Audio layout.")
	self._full_volume_db = AudioServer.get_bus_volume_db(self._bus_index)

func create_channel(channel_name: String) -> GMCChannel:
	var channel = GMCChannel.new(channel_name, self)
	self.channels.append(channel)
	return channel


func duck(settings) -> void:
	if not settings is DuckSettings:
		settings = DuckSettings.new(settings)
	#var current_duck = null if self.duckings.is_empty() else self.duckings[0]
	self.duckings.append(settings)
	self.duckings.sort_custom(
		func(a, b): return a.attenuation < b.attenuation
	)
	# If this duck is not the strongest, do nothing
	if settings != self.duckings[0]:
		self.log.debug("Ducking %s is not the strongest, no volume adjustment triggered.", settings)
		return

	if self._active_duck:
		self._active_duck.kill()

	self._active_duck = self._create_duck_tween(settings.attenuation, settings.attack)
	# We need to know how long to release, so attach it as metadata
	self._active_duck.set_meta("release", settings.release)

	if not self._duck_release_timer:
		self._duck_release_timer = Timer.new()
		self._duck_release_timer.one_shot = true
		self._duck_release_timer.timeout.connect(self.duck_release)
		self.add_child(self._duck_release_timer)
	# Track which duck we are timing
	self._duck_release_timer.set_meta("ducking", settings)
	self._duck_release_timer.start(settings.duration)
	self.log.info("Ducking %s by %s over %ss, will last %s" % [self.name, settings.attenuation, settings.attack, settings.duration])

func duck_release() -> void:
	# Remove this duck from the list of duckings
	var last_duck: DuckSettings = self._duck_release_timer.get_meta("ducking")
	self.duckings.erase(last_duck)
	var next_duck: DuckSettings
	var time_remaining: float
	# If there is another duck queued, process it with relative time
	while not self.duckings.is_empty():
		next_duck = self.duckings[0]
		self.log.debug("Checking to next ducking: %s" % next_duck)
		# This ducking started a while ago, so find the new release time
		time_remaining = (next_duck.release_time - Time.get_ticks_msec()) / 1000.0
		# If this duck has expired (with a small margin of error), remove
		if time_remaining < 0.15:
			self.log.debug(" - ducking expired, moving on")
			self.duckings.erase(next_duck)
			continue
		break

	# Just in case the math is bad and the release happens before the attack finishes
	if self._active_duck:
		self._active_duck.kill()

	# If there is a next duck in the stack, use that as the release volume
	var attenuation = next_duck.attenuation if next_duck else 0.0
	self._active_duck = self._create_duck_tween(attenuation, last_duck.release)
	self.log.info("Releasing duck on %s over %ss" % [self.name, last_duck.release])

	if next_duck:
		self._duck_release_timer.set_meta("ducking", next_duck)
		self._duck_release_timer.start(time_remaining)
	else:
		self._duck_release_timer.remove_meta("ducking")

func set_bus_volume(value: float):
	AudioServer.set_bus_volume_db(self._bus_index, value)

func set_bus_volume_full(value: float):
	# If the user has changed the system volume, store the new value as "full"
	self.set_bus_volume(value)
	self._full_volume_db = value

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
	#settings["bus"] = self.name

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
	var stream = available_channel.play_with_settings(settings)

	if settings.ducking:
		if stream is AudioStreamRandomizer:
			# TODO: Get current stream from AudioStreamRandomizer:
			# https://github.com/godotengine/godot/pull/88437
			self.log.warn("Unable to duck AudioStreamRandomizer :( ")
			return
		# If this came from an MPFSoundAsset the ducking is already configured
		var duck_settings: DuckSettings = settings.ducking if settings.ducking is DuckSettings else DuckSettings.new(settings.ducking)
		duck_settings.calculate_release_time(Time.get_ticks_msec(), stream)
		duck_settings.bus.duck(duck_settings)

func clear_queue() -> void:
	if not queue:
		return
	for q in queue:
		# Clear any streams from these channels so they can be available again
		if q.get("channel", false):
			q["channel"].stream = null
	# Remove all items from the queue
	queue.clear()

func get_current_sound() -> String:
	for channel in self.channels:
		if channel.playing:
			return channel.stream.resource_path.split("/")[-1]
	return ""


func is_resource_playing(filepath: String) -> bool:
	for channel in self.channels:
		if channel.playing and channel.stream.resource_path == filepath:
			return true
	return false


func stop(key: String, settings: Dictionary) -> void:
	# Find the channel playing this file
	for channel in self.channels:
		if channel.stream and channel.stream.get_meta("key") == key and channel.playing and not channel.get_meta("is_stopping", false):
			channel.stop_with_settings(settings)
			return
	# It's possible that the stop was called just for safety.
	# If no channel is found with this file, that's okay.


func _create_duck_tween(attenuation: float, duration: float) -> Tween:
	var duck_tween = self.create_tween()
	duck_tween.tween_method(self.set_bus_volume,
		# Always use the current level in case we're interrupting
		AudioServer.get_bus_volume_db(self._bus_index),
		# TODO: Integrate default values
		self._full_volume_db - attenuation,
		duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	return duck_tween


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
