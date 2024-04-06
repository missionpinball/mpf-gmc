# Copyright 2021 Paradigm Tilt

@tool
extends Node

@onready var duckAttackTimer = Timer.new()
@onready var duckReleaseTimer = Timer.new()
var musicDuck: Tween

var busses = {}

var _music_loop_channel: AudioStreamPlayer

# Counter for the current loop number of the music (zero-indexed)
var _music_loops: int = 0
# Counter for what the next loop number will be
var _music_loop_pending: int = 0

var duck_attenuation := 8
var duck_attack := 0.5
var duck_release := 0.5
var duck_settings
var unduck_level: int = AudioServer.get_bus_volume_db(1)

# TODO: Remove default duck, or make customizable/optional
const default_duck = {
    "delay": 0.0,
    "attack": 0.4,
    "attenuation": 8,
    "release_point": 0.3,
    "release": 0.6
}

func initialize(config: ConfigFile) -> void:
    for i in range(0, AudioServer.bus_count):
        var bus_name = AudioServer.get_bus_name(i)
        print("Found bus %s" % bus_name)
        self.busses[bus_name] = { "name": bus_name, "channels": [] }
    if config.has_section("sound_system"):
        for key in config.get_section_keys("sound_system"):
            var settings = config.get_value("sound_system", key)
            print("Sound system config '%s' has setting: %s" % [key, settings])
            var target_bus = settings['track'] if settings.get('bus') else key
            if target_bus in self.busses:
                print("Going to set up a config for '%s'!!" % target_bus)
                assert(settings.get("type"), "Sound system bus '%s' missing required field 'type'." % target_bus)
                var bus_type = settings["type"]
                self.busses[target_bus]["type"] = bus_type
                var channels_to_make = 2 if bus_type == "solo" else settings.get("simultaneous_sounds", 1)
                for i in range(0, channels_to_make):
                    var channel = AudioStreamPlayer.new()
                    channel.name = "%s_%s" % [target_bus, i+1]
                    self.busses[target_bus].channels.append(channel)
                    self.add_child(channel)
                # Sequential busses get a queue to store pending sounds
                if bus_type == "sequential":
                    self.busses[target_bus]["queue"] = []
        print("Finished configuring sound system: %s" % self.busses)

func _ready() -> void:
    for bus in self.busses.values():
        if bus.type == "sequential":
            for track in bus.tracks:
                track.finished.connect(self._on_queue_track_finished.bind(bus.name))
    duckAttackTimer.one_shot = true
    duckAttackTimer.timeout.connect(self._duck_attack)
    duckReleaseTimer.one_shot = true
    duckReleaseTimer.timeout.connect(self._duck_release)
    MPF.game.volume.connect(self._on_volume)
    MPF.server.connect("clear", self._on_clear_context)
    set_process(false)

func play_sounds(s: Dictionary) -> void:
    assert(typeof(s) == TYPE_DICTIONARY, "Sound player called with non-dict value: %s" % s)
    print("PLAYIDNG SOUNDS from dictionary %s" % s)
    for asset in s.settings.keys():
        var settings = s.settings[asset]
        var track: String = settings["track"] if settings.get("track") else "sfx"
        var file: String = settings.get("file", asset)
        var action: String = settings.get("action", "play")
        settings['context'] = settings.get("custom_context", s.context)

        if action == "stop" or action == "loop_stop":
            self.stop(file, track, settings)
            return
        self.play(file, track, settings)

func play(filename: String, track: String, settings: Dictionary = {}) -> void:
    MPF.log.info("play called for %s on %s with settings %s" % [filename, track, settings])
    # Accept an absolute filepath too
    var filepath: String
    if filename.left(4) == "res:":
        filepath = filename
    else:
        filepath = "res://assets/%s/%s" % ["voice" if track == "callout" else track, filename]
    var available_channel: AudioStreamPlayer
    settings["track"] = track

    # Clear out the queue if necessary, to free up channels
    if settings.get("clear_queue", false):
        self.clear_queue(settings["track"])

    # # Callouts supercede voice tracks. If there is a callout, stop voices
    # if track == "callout" and _voice_1.playing and settings.get("block_voice", true):
    #     self._stop(_voice_1, { "fade_out": 0.5 })
    #     # Clear out any other queued voices
    #     queued_voice = []

    # Check our channels to see if (1) one is empty or (2) one already has this
    else:
        available_channel = self._find_available_channel(track, filepath, settings)

    # Look for some music so we can replace or queue
    if track == "music" :
        for c in self._get_channels("music"):
            if c.playing and c != available_channel:
                self._stop(c, settings)

    # If the available channel we got back is already playing, it's playing this track
    # and we don't need to do anything further.
    if available_channel and available_channel.playing:
        MPF.log.debug("Recevied available channel that's already playing, no-op.")
        return

    if not available_channel:
        # Queue the filename if this track type has a queue
        var target_queue = self.busses[track].get("queue")
        if target_queue:
            # By default, max queue time is one minute (tracked in milliseconds)
            var max_queue_time: int = settings.get("max_queue_time", 60000)
            if max_queue_time != 0:
                target_queue.append(self._generate_queue_item(filename, max_queue_time, settings))
        return
    if not available_channel.stream:
        available_channel.stream = self._load_stream(filepath)
    if not available_channel.stream:
        MPF.log.error("Failed to load stream for filepath '%s' on channel %s", [filepath, available_channel])
        return
    self._play(available_channel, settings)

func _play(channel: AudioStreamPlayer, settings: Dictionary) -> void:
    if not channel.stream:
        MPF.log.error("Attempting to play on channel %s with no stream. %s ", [channel, settings])
        return

    MPF.log.debug("playing %s (%s) on %s with settings %s", [channel.stream.resource_path, channel.stream, channel, settings])
    channel.set_meta("context", settings.context)
    var start_at: float = settings["start_at"] if settings.get("start_at") else 0.0
    var fade_in: float = settings["fade_in"] if settings.get("fade_in") else 0.0
    # Music is OGG, which doesn't support loop begin/end
    if settings.get("track") == "music" and channel.stream is AudioStreamOggVorbis:
        # By default, loop the music, but allow an override
        channel.stream.loop = settings.get("loop", true)
    elif start_at == -1.0:
        # Map the sound start position relative to the music position
        start_at = fmod(_music_loop_channel.get_playback_position(), channel.stream.get_length())

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
    tween.tween_completed.connect(self._on_fade_complete.bind(tween, "play"))
    $Tweens.add_child(tween)
    tween.start()
    channel.set_meta("tween", tween)

func stop(filename: String, track: String, settings: Dictionary) -> void:
    var filepath: String = "res://assets/%s/%s" % [track, filename]
    # Find the channel playing this file
    for channel in self._get_channels(track):
        if channel.stream and channel.stream.resource_path == filepath:
            self._stop(channel, settings)
            return
    # It's possible that the stop was called just for safety.
    # If no channel is found with this file, that's okay.


func _stop(channel: AudioStreamPlayer, settings: Dictionary, action: String = "stop") -> void:
    if settings.get("action") == "loop_stop":
        # The position is reset when the loop mode changes, so store it first
        var pos: float = channel.get_playback_position()
        channel.stream.loop_mode = 0
        # Play the track to the end of the file
        channel.play(pos)
        return
    if not settings.get("fade_out"):
        channel.stop()
        channel.volume_db = 0.0
        return
    var tween = self.create_tween()
    tween.tween_property(channel, "volume_db", -80.0, settings["fade_out"]) \
        .set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
    tween.tween_completed.connect(self._on_fade_complete.bind(tween, action))
    $Tweens.add_child(tween)
    tween.start()
    channel.set_meta("tween", tween)

func stop_all(fade_out: float = 1.0) -> void:
    MPF.log.debug("STOP ALL called with fadeout of %s" , fade_out)
    duck_settings = null
    # Clear any queued tracks as well, lest they be triggered after the stop
    for track in self.busses.keys():
        self.clear_queue(track)
    var tween = self.create_tween() if fade_out > 0 else null
    for channel in $Channels.get_children():
        if channel.playing and not channel.get_meta("is_stopping", false):
            if tween:
                tween.tween_property(channel, "volume_db", -80.0, fade_out) \
                    .set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
                channel.set_meta("is_stopping", true)
            else:
                channel.stop()
                channel.volume_db = 0.0
    if tween:
        tween.tween_completed.connect(self._on_fade_complete.bind(tween, "stop_all"))
        $Tweens.add_child(tween)
        tween.start()
    else:
        for t in $Tweens.get_children():
            $Tweens.remove_child(t)
            t.remove_all()
            t.queue_free()
        set_process(false)

func clear_queue(track: String) -> void:
    var queue_to_clear = self.busses[track].get("queue")
    if not queue_to_clear:
        MPF.log.error("Track '%s' does not have a queue to clear.", track)
        return
    for q in queue_to_clear:
        # Clear any streams from these channels so they can be available again
        if q.get("channel", false):
            q["channel"].stream = null
    # Remove all items from the queue
    queue_to_clear.clear()

func _on_fade_complete(channel, _nodePath, tween, action) -> void:
    $Tweens.remove_child(tween)
    # Presumably the signal will disconnect when the tween is removed
    tween.remove_all()
    tween.queue_free()
    # If this is a stop action, stop the channel as well
    if action == "stop" or action == "clear":
        MPF.log.debug("Fade out complete on channel %s" % channel)
        channel.stop()
        channel.volume_db = 0.0
    # If this is a stop_all action, stop all the channels
    elif action == "stop_all":
        # TODO: Add a timestamp to stop_all callback and automatically prevent
        # stoppage of tracks started after the stop_all call. In the meantime,
        # hard-code tracks that should not be stopped via stop_all.
        var non_stop_resources := ["res://assets/sfx/stinger.wav", "res://assets/sfx/sof-bonus.ogg"]
        for c in $Channels.get_children():
            if c.stream and not c.stream.resource_path in non_stop_resources:
                c.stop()
                c.volume_db = 0.0
                c.set_meta("is_stopping", false)
        set_process(false)
    elif action == "play":
        MPF.log.debug("Fade in to %0.2f complete on channel %s", [channel.volume_db, channel])
    if action == "clear":
        channel.stream = null

func _get_channels(track: String):
    if track not in self.busses:
        MPF.log.error("Invalid track %s requested", track)
    return self.busses[track].channels

func _find_available_channel(track: String, filepath: String, settings: Dictionary) -> AudioStreamPlayer:
    var available_channel
    print("Looking for channel for %s in channels" % track)
    for channel in self._get_channels(track):
        print(" - trying channel %s" % channel)
        if channel.stream and channel.stream.resource_path == filepath:
            # If this file is *already* playing, keep playing
            if channel.playing:
                # If this channel has a tween, override it
                if channel.has_meta("tween") and is_instance_valid(channel.get_meta("tween")):
                    # Stop the tween
                    var tween = channel.get_meta("tween")
                    tween.stop_all()
                    self._on_fade_complete(channel, null, tween,  "cancel")
                # If the channel does not have a tween, let it continue playing
                else:
                    # If there is an explicit start time, jump there unless told otherwise
                    if settings.get("start_at") != null and not settings.get("keep_position", false):
                        channel.seek(settings["start_at"])
            MPF.log.debug("Channel %s already has resource %s, playing from memory", [channel, filepath])
            available_channel = channel
        elif not available_channel:
            if not channel.stream:
                MPF.log.debug("Channel %s has no stream, making it the available channel" % channel)
                available_channel = channel
            elif not channel.playing:
                # Don't take a channel that's queued
                if track == "music" and self.queued_music and channel == self.queued_music[0]["channel"]:
                    MPF.log.debug("Channel %s is queued up with music, not making it available", channel)
                else:
                    MPF.log.debug("Channel %s has a stream %s but it's not playing, making it available" % [channel, channel.stream])
                    available_channel = channel
                    available_channel.stream = null
    return available_channel

func _generate_queue_item(filename: String, max_queue_time: int, settings: Dictionary) -> Dictionary:
    return {
        "filename": filename,
        "expiration": Time.get_ticks_msec() + (1000 * max_queue_time),
        "settings": settings
    }

func _on_queue_track_finished(bus_name: String) -> void:
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

func _on_volume(track: String, value: float, _change: float):
    var bus_name: String = track.trim_suffix("_volume")
    # The Master bus is fixed and capitalized
    if bus_name == "master":
        bus_name = "Master"
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func get_current_sound(track: String) -> String:
    var channels = self._get_channels(track)
    for channel in channels:
        if channel.playing:
            return channel.stream.resource_path.split("/")[-1]
    return ""

func is_resource_playing(track: String, filepath: String) -> bool:
    var channels = self._get_channels(track)
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
    MPF.log.debug("Ducking voice clip down with settings: %s", duck_settings)
    duckReleaseTimer.start(duck_settings.release_timestamp)


func _duck_release():
    if not duck_settings:
        return
  # If the music is ducked, unduck it
    if AudioServer.get_bus_volume_db(1) < self.unduck_level:
        MPF.log.debug("Unducking voice clip back to %0.2f db over %0.2f seconds", [self.unduck_level, duck_release])
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
            if channel.has_meta("context") and channel.get_meta("context") == context_name and channel.playing:
                # TODO: Respect fade_out settings for context-stopped sounds
                channel.stop()
