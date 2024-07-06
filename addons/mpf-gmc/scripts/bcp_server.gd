# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

extends LoggingNode
class_name GMCServer


enum ServerStatus { IDLE, WAITING, LAUNCHING, CONNECTED, ERROR }

signal bonus(payload)
signal mpf_timer(payload)
signal options(payload)
signal item_highlighted(payload)
signal player_var(value, prev_value, change, player_num)
signal service(payload)
signal clear(mode_name)
signal status_changed(status)

# A list of events that trigger their own automatic signals
var auto_signals := []
# A list of event names to register in MPF
var registered_events := []
# A map of event handlers added by MPFVariables
var registered_handlers := {}
# The port we will listen on
var port := 5050
# The polling frequency to poll the server for data
var poll_fps: int = 120
# The current status of the server
var status: ServerStatus = ServerStatus.IDLE

# A library of static methods for parsing the incoming BCP data
var _bcp_parse = preload("bcp_parse.gd")
# A connected MPF Client
var _client: StreamPeerTCP
# Our WebSocketServer instance
var _server: TCPServer = TCPServer.new()
# A separate thread for running the BCP Server
var _thread: Thread

# A mutex for managing threadsafe operations
@onready var _mutex := Mutex.new()

###
# Built-in virtual methods
###

func _ready() -> void:
	# Wait until a server is actively listening before polling for clients
	set_process(false)

func _exit_tree():
	self.stop(true)

func _process(_delta: float) -> void:
	if not _client and _server.is_connection_available() == true:
		self.log.info("Client connection is available.")
		_client = _server.take_connection()
		var err = _thread.start(self._thread_poll, Thread.Priority.PRIORITY_LOW)
		if err != OK:
			self.log.error("Error spawning BCP poll thread: %s", error_string(err))
			self.status = ServerStatus.ERROR
		else:
			self.log.log("Client connected from %s:%s", [_client.get_connected_host(), _client.get_connected_port()])
			self.status = ServerStatus.CONNECTED
			# No need to run _process() while we have an active client connection
			set_process(false)
		status_changed.emit(self.status)

## Handle connection validation before public on_connect method
func _on_connect(payload: Dictionary) -> void:
	if payload.controller_name == "Mission Pinball Framework":
		if not MPF.validate_min_version(payload.controller_version):
			self.log.error("MPF %s does not meet minimum version requirement %s", [payload.controller_version, MPF.MPF_MIN_VERSION])
			assert(false, "GMC requires MPF version %s, but found %s." % [MPF.MPF_MIN_VERSION, payload.controller_version])
	self.on_connect()

###
# Public Methods
###

func set_status(new_status: ServerStatus):
	self.status = new_status
	status_changed.emit(self.status)

func deferred_game(method: String, result=null) -> void:
	var callable = Callable(MPF.game, method)
	if result:
		callable.call(result)
	else:
		callable.call()

func deferred_mc(method: String, result=null) -> void:
	var callable = Callable(MPF.media, method)
	if result:
		callable.call(result)
	else:
		callable.call()

func deferred_game_player(result) -> void:
	MPF.game.update_player(result)

func deferred_scene(scene_res: String) -> void:
	get_tree().change_scene_to_file(scene_res)

func deferred_scene_to(scene_pck: Resource) -> void:
	get_tree().change_scene_to_packed(scene_pck)

## Call this method from your main scene to open a port for MPF connections
func listen() -> void:
	# If we are already spawning, keep that status
	if self.status != ServerStatus.LAUNCHING:
		self.status = ServerStatus.WAITING
		status_changed.emit(self.status)
	_thread = Thread.new()
	var err = _server.listen(port)
	if err != OK:
		self.log.error("Unable to start GMC: %s", error_string(err))
		# The _process() method polls for client connections. If the server
		# isn't listening, there's no reason to poll for clients.
		set_process(false)
		return
	self.log.info("GMC listening on port %s", port)
	set_process(true)

## Post an event to MPF
func send_event(event_name: String, bounceback: bool = true) -> void:
	_send("trigger?name=%s" % event_name)
	if bounceback:
		self._bounceback(event_name)


func send_event_with_args(event_name: String, args: Dictionary, bounceback: bool = true) -> void:
	if not args or args.is_empty():
		return self.send_event(event_name)
	var event_string = _bcp_parse.encode_event_args(event_name, args)
	_send("trigger?%s" % event_string)
	if bounceback:
		self._bounceback(event_name, args)

func send_switch(switch_name: String, state: int = -1) -> void:
	var message = "switch?name=%s&state=%s" % [switch_name, state]
	_send(message)

## Send a specialized Service Mode command to MPF
func send_service(subcommand: String, values: PackedStringArray = []) -> void:
	var suffix: String = "&values=%s" % ",".join(values) if values else ""
	self._send("service?subcommand=%s&sort=bool:false%s" % [subcommand, suffix])

## Set a machine variable in MPF
func set_machine_var(var_name: String, value, persist=null) -> void:
	# Only send the persist flag if explicitly passed, otherwise let the
	# MPF config value take precedent
	var persist_string = ""
	if persist != null:
		persist_string = "&persist=%s" % persist
	self._send("set_machine_var?name=%s&value=%s%s" % [var_name, self.wrap_value_type(value), persist_string])

## Register an event handler for an MPFVariable
func add_event_handler(event: String, handler: Callable) -> void:
	# Add a listener for this event if we don't already have one
	if event not in registered_handlers:
		self.log.debug("Registering MPF event trigger for event '%s'", event)
		self._send("register_trigger?event=%s" % event)
		registered_handlers[event] = []
	if handler not in registered_handlers[event]:
		registered_handlers[event].append(handler)
		self.log.debug("Adding handler %s to event trigger for event '%s'", [handler, event])

func remove_event_handler(event: String, handler: Callable) -> void:
	# TODO: Any fallback logic or error catching if it's not here?
	self.log.debug("Removing handler %s from event trigger for event '%s'", [handler, event])
	registered_handlers[event].erase(handler)
	# If there are no more handlers, unsubscribe from this event
	if not registered_handlers[event] and event not in self.registered_events and event not in self.auto_signals:
		self.log.debug("Deregistering MPF event trigger for event '%s' because it has no more handlers", event)
		self._send("remove_trigger?event=%s" % event)
		registered_handlers.erase(event)

## Disconnect the BCP server
func stop(is_exiting: bool = false) -> void:
	self.log.log("Shutting down BCP Server and %s", "will not restart" if is_exiting else "awaiting new connection")
	# Lock the mutex to prevent the BCP thread from polling
	_mutex.lock()
	_server.stop()
	if _client:
		# Say goodbye to MPF!
		_send("goodbye")
		_client.disconnect_from_host()
		_client = null
	_mutex.unlock()

	if _thread and _thread.is_started():
		_thread.wait_to_finish()

	if not is_exiting:
		self.on_disconnect()
		# Set an exit code so we know MPF is the cause of the exit
		get_tree().quit(6)
		# TODO: Add a configuration option to exit-on-disconnect and if false,
		# call self.deferred_scene("res://Main.tscn") instead of quit()

# Use the BCP syntax to define the type
func wrap_value_type(value) -> String:
	match typeof(value):
		TYPE_BOOL:
			value = "bool:%s" % value
		TYPE_INT:
			value = "int:%s" % value
		TYPE_FLOAT:
			value = "float:%s" % value
	return value

###
# The following public methods can be overridden in a subclass for game-specific behavior
###

func on_ball_start(_ball, _player_num) -> void:
	pass

func on_ball_end() -> void:
	pass

## Called when a BCP connection is opened successfully.
func on_connect() -> void:
	pass

func on_disconnect() -> void:
	pass

func on_input(_event_payload: PackedStringArray) -> void:
	pass

func on_message(message: Dictionary) -> Dictionary:
	return message

func on_mode_start(_mode_name: String) -> void:
	pass

func on_stop() -> void:
	pass

###
# Private Methods
###

func _send(message: String) -> void:
	if not _client:
		return
	self.log.verbose("Sending: %s", message)
	_client.put_data(("%s\n" % message).to_ascii_buffer())

func _bounceback(event_name: String, args = null):
	# If any handlers are registered for this event, call them directly
	if event_name in self.registered_handlers:
		for h in self.registered_handlers[event_name]:
			if args:
				h.call_deferred(args)
			else:
				h.call_deferred()

func _thread_poll(_userdata=null) -> void:
	# TBD: What is the optimal polling rate for the BCP client?
	var _start = Time.get_ticks_msec()
	var delay = 1000.0 /poll_fps
	while _client:
		# If the mutex is locked, the system is shutting down
		if not _mutex.try_lock():
			return
		var bytes = _client.get_available_bytes()
		if not bytes:
			OS.delay_msec(delay)
		else:
			var err = _client.poll()
			if err != OK:
				push_error("BCP client error: %s" % error_string(err))
				_client.disconnect_from_host()
				_client = null
				call_deferred("stop")
				return
			var messages := _client.get_string(bytes).split("\n")
			for message_raw in messages:
				if message_raw.is_empty():
					continue
				self.log.verbose("Received: %s", message_raw)
				var message: Dictionary = _bcp_parse.parse(message_raw)
				# Log any errors
				if message.has("error"):
					self.log.error(message.error)

				# Known signals can be broadcast with arbitrary payloads
				if message.cmd in auto_signals:
					message.cmd = "signal"

				# If on_message() returns null, the message has been handled
				# and no further action is necessary.
				if self.on_message(message) == null:
					continue

				match message.cmd:
					"ball_end":
						call_deferred("on_ball_end")
					"ball_start":
						call_deferred("on_ball_start", message.ball, message.player_num)
					"buses_play":
						call_deferred("deferred_mc", "play", message)
					"goodbye":
						_send("goodbye")
						call_deferred("stop")
						# Resume polling for new client connections
						call_deferred("set_process", true)
					"hello":
						_send("hello")
						call_deferred("_on_connect", message)
					"item_highlighted":
						call_deferred("emit_signal", "item_highlighted", message)
					"list_coils":
						call_deferred("emit_signal", "service", message)
					"list_lights":
						call_deferred("emit_signal", "service", message)
					"list_switches":
						call_deferred("emit_signal", "service", message)
					"machine_variable":
						call_deferred("deferred_game", "update_machine", message)
					"mode_list":
						call_deferred("deferred_game", "update_modes", message)
					"mode_start":
						if message.name == "game":
							call_deferred("deferred_game", "reset")
						call_deferred("on_mode_start", message.name)
					"mode_stop":
						pass
					"player_added":
						call_deferred("deferred_game", "add_player", message)
					"player_turn_start":
						call_deferred("deferred_game", "start_player_turn", message)
					"player_variable":
						call_deferred("deferred_game_player", message)
					"reset":
						self.log.info("Resetting connection with BCP client")
						_send("reset_complete")
						# Core MPF events
						_send("monitor_start?category=core_events")
						_send("monitor_start?category=service_events")
						_send("monitor_start?category=modes")
						_send("monitor_start?category=player_vars")
						_send("monitor_start?category=machine_vars")
						# Standard events
						_send("register_trigger?event=item_highlighted")
						_send("register_trigger?event=bonus_entry")
						_send("register_trigger?event=high_score_enter_initials")
						_send("register_trigger?event=high_score_award_display")
						# Custom events
						for e in self.registered_events + self.auto_signals:
							_send("register_trigger?event=%s" % e)
					"service":
						call_deferred("emit_signal", "service", message)
					"service_mode_entered":
						# The default service.yaml includes a slide_player for service slide
						pass
					"settings":
						call_deferred("deferred_game", "update_settings", message)
					"signal":
						call_deferred("emit_signal", message.name, message)
					"slides_play":
						call_deferred("deferred_mc", "play", message)
					"slides_clear", "widgets_clear":
						# TBD: Need to distinguish slides/widgets/sounds?
						# Don't think so, all config_players have the same callback
						# so all three will post at the same time.
						call_deferred("emit_signal", "clear", message.context)
					"sounds_clear":
						pass
					"sounds_play":
						call_deferred("deferred_mc", "play", message)
					"timer":
						call_deferred("emit_signal", "mpf_timer", message)
					"widgets_play":
						call_deferred("deferred_mc", "play", message)
					_:
						if message.get("name") not in self.registered_handlers:
							self.log.warning("No handler defined for BCP action %s", message_raw)

				# If any handlers are registered for this event, post them
				if message.get("name") in self.registered_handlers:
					for h in self.registered_handlers[message.name]:
						h.call_deferred(message)

		# Free the mutex in case the main thread is trying to shut down
		_mutex.unlock()
