# Godot BCP Server
# For use with the Mission Pinball Framework https://missionpinball.org
# Original code © 2021 Anthony van Winkle / Paradigm Tilt
# Released under the MIT License

extends Node

enum ServerStatus { IDLE, WAITING, LAUNCHING, CONNECTED, ERROR }

signal switch(payload)
signal light(payload)
signal status_changed(status)
signal player_added(num)
signal update_device(payload)
signal update_player_var(name, value, num)
signal update_machine_var(name, value)
signal update_modes(payload)

# The port we will listen on
var port := 5051
# The polling frequency to poll the server for data
var poll_fps: int = 120
# The current status of the server
var status: ServerStatus = ServerStatus.IDLE

# A connected MPF Client
var _client: StreamPeerTCP
# A timer to mitigate updates
var time: float = 0.0

###
# Built-in virtual methods
###

func _ready() -> void:
	_client = StreamPeerTCP.new()
	print("Opening client connection on port %s" % port)

func _exit_tree():
	self.disconnect_client()

func _process(delta: float) -> void:

	time += delta
	if time < 0.1:
		return
	time = 0.0

	if self.status != ServerStatus.CONNECTED:
		self.listen()
		return

	var err = _client.poll()
	if err != OK or _client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		if _client.get_status() != StreamPeerTCP.STATUS_CONNECTING:
			self.disconnect_client()
		return

	var bytes = _client.get_available_bytes()
	if not bytes:
		return

	var messages := _client.get_string(bytes).split("\n")
	for message_raw in messages:
		if message_raw.is_empty():
			continue
		#print("Received: %s", message_raw)
		var message: Dictionary = parse(message_raw)
		# Log any errors
		if message.has("error"):
			printerr(message.error)

		if message.cmd == "monitored_event":
			message.cmd = message.event_name

		match message.cmd:
			"device":
				self.update_device.emit(message)
			"goodbye":
				_send("goodbye")
			"hello":
				_send("hello")
			"list_coils":
				call_deferred("emit_signal", "service", message)
			"list_lights":
				call_deferred("emit_signal", "service", message)
			"list_switches":
				call_deferred("emit_signal", "service", message)
			"machine_variable":
				self.update_machine_var.emit(message.name, message.value)
			"mode_list":
				self.update_modes.emit(message)
			"player_added":
				self.player_added.emit(message.event_kwargs.num)
			"player_variable":
				self.update_player_var.emit(message.name, message.value, int(message.player_num))
			"reset":
				print("Resetting connection with BCP client")
				_send("reset_complete")

			_:
				push_warning("No handler defined for BCP action %s", message_raw)



###
# Public Methods
###

func set_status(new_status: ServerStatus):
	self.status = new_status
	status_changed.emit(self.status)


## Call this method from your main scene to open a port for MPF connections
func listen() -> void:
	# If we are already spawning, keep that status
	if self.status != ServerStatus.LAUNCHING:
		self.status = ServerStatus.WAITING
		status_changed.emit(self.status)

	var st = _client.get_status()
	if st == StreamPeerTCP.STATUS_NONE:
		var e = _client.connect_to_host("localhost", port)
		if e != OK:
			_client.disconnect_from_host()
			return

	var err = _client.poll()
	if err != OK:
		_client.disconnect_from_host()
		return

	st = _client.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTED:
		self.status = ServerStatus.CONNECTED
		print("Connected!")
		# Core MPF events
		_send("monitor_start?category=modes")
		_send("monitor_start?category=player_vars")
		_send("monitor_start?category=machine_vars")
		# Standard events
		_send('monitor_start?category=devices')
		_send('monitor_start?category=events')


func send_switch(switch_name: String, state: int = -1) -> void:
	var message = "switch?name=%s&state=%s" % [switch_name, state]
	_send(message)

func disconnect_client():
	_client.disconnect_from_host()
	self.status = ServerStatus.IDLE

###
# Private Methods
###

func _send(message: String) -> void:
	if not _client:
		return
	print("Sending: %s" % message)
	_client.put_data(("%s\n" % message).to_ascii_buffer())


# TODO: Define a type for the response dictionary
func parse(message: String) -> Dictionary:
	var cmd: String
	var result = {}

	if "?" in message:
		var split_message := message.split("?")
		cmd = split_message[0]
		result = string_to_obj(split_message[1], cmd)
	else:
		cmd = message
	if cmd == "trigger":
		# This creates a standard signal "mpf_timer" so any
		# timer event doesn't need an individual signal
		if result.name.substr(0,6) == "timer_":
			cmd = "timer"
		elif result.name.substr(0,8) == "service_" and result.name != "service_mode_entered":
			cmd = "service"
		else:
			cmd = result.name

	result.cmd = cmd
	return result


func string_to_obj(message: String, _cmd: String) -> Dictionary:
	var result := {}
	if message.substr(0, 5) == "json=":
		var json = JSON.parse_string(message.substr(5))
		if json == null:
			result.error = "Error %s parsing trigger: %s" % [json.error, message]
			return result
		else:
			return json

	var chunks = message.split("&")
	for chunk in chunks:
		# This algorithm looks verbose but it's the fastest. I tested.
		var pair = chunk.split("=")
		var raw_value: String = pair[1]
		if ":" in raw_value:
			var type_hint = raw_value.get_slice(":", 0)
			var hint_value = raw_value.get_slice(":", 1)
			# Basic typesetting
			match type_hint:
				"int":
					result[pair[0]] = int(hint_value)
				"float":
					result[pair[0]] = float(hint_value)
				"bool":
					result[pair[0]] = hint_value == "True"
				"NoneType":
					result[pair[0]] = null
				"_":
					push_warning("Unknown type hint %s in message %s" % [raw_value, message])
					result[pair[0]] = hint_value
		else:
			result[pair[0]] = raw_value.uri_decode()
	return result
