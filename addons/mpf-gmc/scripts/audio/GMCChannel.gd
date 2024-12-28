extends AudioStreamPlayer
class_name GMCChannel


var tweens: Array[Tween]
var markers: Array[SoundMarker]

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger

func _init(n: String, b: GMCBus):
	self.name = n
	# This sets the AudioStreamPlayer.bus property to control its playback,
	# and must be set to the StringName of the bus being used.
	self.bus = b.name
	# Channels don't need their own logs, just use the GMCBus log
	self.log = b.log

func _exit_tree():
	# Seems like this would be default in Godot, but no. Not stopping on exit
	# causes memory leaks, so make sure to stop.
	self.stop()

func _process(_delta: float) -> void:
	var playback_time: float = self.get_playback_position()
	var remaining_markers: int = 0
	for m in self.markers:
		remaining_markers += m.mark(playback_time)
	if not remaining_markers:
		set_process(false)

func load_stream(filepath: String) -> AudioStream:
	self.stream = ResourceLoader.load(filepath, "AudioStreamOGGVorbis" if filepath.get_extension() == "ogg" else "AudioStreamSample") as AudioStream
	return self.stream

func play_with_settings(settings: Dictionary) -> AudioStream:
	if not self.stream:
		printerr("Attempting to play on channel %s with no stream. %s ", [self, settings])
		return

	self.log.debug("playing %s (%s) on %s with settings %s", [self.stream.resource_path, self.stream, self, settings])
	self.stream.set_meta("context", settings.context)
	self.stream.set_meta("key", settings.key)
	self.stream_paused = false

	var start_at: float = settings["start_at"] if settings.get("start_at") else 0.0
	var fade_in: float = settings["fade_in"] if settings.get("fade_in") else 0.0
	if settings.get("fade_out"):
		self.stream.set_meta("fade_out", settings.fade_out)

	if settings.get("loops"):
		if settings["loops"] == -1:
			# For infinite looping of OGG/WAV/MPF, use the native loop
			# OGG and MPF use the 'loop' property, while WAV uses 'loop_mode
			if self.stream is AudioStreamOggVorbis or self.stream is AudioStreamMP3:
				self.stream.loop = true
			elif self.stream is AudioStreamWAV:
				self.stream.loop_mode = 1
			else:
				self._connect_loop(settings["loops"])
		else:
			self._connect_loop(settings["loops"])

	# TODO: Support marker events
	if settings.get("events_when_started"):
		for e in settings["events_when_started"]:
			MPF.server.send_event(e)
	if settings.get("events_when_stopped"):
		# Store a reference to the callable so it can be disconnected
		var callable = self._trigger_events.bind("stopped", settings["events_when_stopped"] as Array[String])
		self.stream.set_meta("events_when_stopped", callable)
		self.finished.connect(callable)

	# Check for markers
	self.markers = settings.get("markers", [] as Array[SoundMarker])
	if self.markers:
		for m in self.markers:
			m.reset()
		set_process(true)
	else:
		set_process(false)

	# If the current volume is less than the target volume, e.g. this was fading out
	# but was re-played, force a quick fade to avoid jumping back to full
	if not fade_in and self.playing and self.volume_db < 0:
		fade_in = 0.5
	if not fade_in:
		# Ensure full volume in case it was tweened out previously
		self.volume_db = linear_to_db(settings["volume"] if settings.get("volume") else 1.0)
		self.play(start_at)
		return self.stream
	# Set the volume and begin playing
	if not self.playing:
		self.volume_db = -80.0
		self.play(start_at)
	var tween: Tween = self.create_tween()
	tween.tween_property(self, "volume_db", 0.0, fade_in).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.finished.connect(self._on_fade_complete.bind(tween, "play"))
	self.tweens.append(tween)
	self.set_meta("tween", tween)
	return self.stream

func clear() -> void:
	self.stop()
	self.volume_db = 0.0
	self.remove_meta("tween")
	self.remove_meta("is_stopping")
	if self.stream and self.stream.has_meta("loops_remaining"):
		self.stream.remove_meta("loops_remaining")
	for c in self.finished.get_connections():
		self.finished.disconnect(c.callable)
	self.stream_paused = false
	self.markers = []
	self.stream = null
	set_process(false)

func pause_with_settings(settings: Dictionary = {}) -> void:
	if not self.stream or not self.playing or stream.get_meta("is_stopping", false):
		return

	var fade_out: float = settings["fade_out"] if settings.get("fade_out") else 0.0
	if not fade_out:
		self.stream_paused = true
		return

	var tween: Tween = self.create_tween()
	tween.tween_property(self, "volume_db", -80.0, fade_out) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.finished.connect(self._on_fade_complete.bind(tween, "pause"))
	self.tweens.append(tween)
	self.set_meta("tween", tween)

func unpause_with_settings(settings: Dictionary = {}) -> void:
	if not self.stream or not self.stream_paused or stream.get_meta("is_stopping", false):
		return
	var fade_in: float = settings["fade_in"] if settings.get("fade_in") else 0.0
	self.log.debug("Unpausing channel %s with fade_in %s from settings %s" % [self, fade_in, settings])

	self.stream_paused = false
	# If we are fading in, set the volume down
	if fade_in:
		self.volume_db = -80.0
		var tween: Tween = self.create_tween()
		tween.tween_property(self, "volume_db", 0.0, fade_in) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tween.finished.connect(self._on_fade_complete.bind(tween, "unpause"))
		self.tweens.append(tween)
		self.set_meta("tween", tween)

func stop_with_settings(settings: Dictionary = {}) -> void:
	var action: String = settings.get("action", "stop")
	if action == "loop_stop":
		# The position is reset when the loop mode changes, so store it first
		var pos: float = self.get_playback_position()
		self.stream.loop_mode = 0
		# Play the sound to the end of the file
		self.play(pos)
		return
	var fade_out: float = settings["fade_out"] if settings.get("fade_out") else 0.0
	if not fade_out and self.stream.has_meta("fade_out"):
		# On a stop-all call, bypass the stream's built-in fade_out value
		if action != "stop_all":
			fade_out = self.stream.get_meta("fade_out")
	if not fade_out:
		self.clear()
		return
	var tween: Tween = self.create_tween()
	tween.tween_property(self, "volume_db", -80.0, fade_out) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.finished.connect(self._on_fade_complete.bind(tween, action))
	self.tweens.append(tween)
	self.set_meta("tween", tween)
	self.set_meta("is_stopping", true)

func _on_fade_complete(tween: Tween, action: String) -> void:
	self.tweens.erase(tween)
	# If this is a stop_all action, finish all the channels that are stopping
	# If this is a stop action, stop the channel
	match action:
		"stop", "clear":
			self.log.debug("Fade out complete on channel %s, will stop now.", self)
			self.clear()
		"play":
			self.log.debug("Fade in to %0.2f complete on channel %s.", [self.volume_db, self])
		"pause":
			self.log.debug("Fade out complete on channel %s, will pause now.", self)
			self.stream_paused = true

func _connect_loop(loop_count):
	# The first loop is playing immediately, so *remaining* is count minus one
	self.stream.set_meta("loops_remaining", loop_count - 1)
	self.finished.connect(self._on_loop)

func _on_loop() -> void:
	var loops_remaining = self.stream.get_meta("loops_remaining")
	self.log.debug("Looping for %s, %s loops remaining" % [self, loops_remaining])
	if loops_remaining == 0:
		self.stop_with_settings()
		return
	if loops_remaining > 0:
		self.stream.set_meta("loops_remaining", loops_remaining - 1)
	self.play()

func _trigger_events(state: String, events: Array) -> void:
	for e in events:
		MPF.server.send_event(e)
	self.finished.disconnect(self.stream.get_meta("events_when_%s" % state))
	self.stream.remove_meta("events_when_%s" % state)

func _to_string() -> String:
	return "<GMCChannel:%s:current_stream=%s>" % [self.name, "%s" % self.stream if self.stream else "None"]
