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
	available_channel.play_with_settings(settings)

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
