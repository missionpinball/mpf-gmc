@tool
extends Control

var log_file
var time := 0.0
# @onready var text_target: TextEdit = self.get_node("VBoxContainer").get_node("TextEdit")
var text_target
var timer: Timer

# The port we will listen on
var port := 5058
# The polling frequency to poll the server for data
var poll_fps: int = 1 # 120

var _client: StreamPeerTCP
var _server: TCPServer
var _thread: Thread

@export var terminal: TextEdit

# A mutex for managing threadsafe operations
@onready var _mutex := Mutex.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	terminal.insert_text_at_caret("Hello I'm mpf output panel\n")
	# text_target = TextEdit.new()
	# text_target.text = "Buttface McGee"
	# text_target.size_flags_vertical = SizeFlags.SIZE_EXPAND_FILL
	# self.add_child(text_target)

	terminal.insert_text_at_caret("Here goes teh server\n")
	self._server = TCPServer.new()
	self.listen()
	# print("registering message capture")
	# EngineDebugger.register_message_capture("mpf_log_created", self._on_log_created)
	# print("Does have capture? %s" % EngineDebugger.has_capture("mpf_log_created"))

func _exit_tree() -> void:
	self.stop()

func _on_log_created(message: String, data: Array) -> bool:
	terminal.insert_text_at_caret("MPF log created found from EngineDebugger with message '%s'\n" % message)
	print(data)
	self._open_log(data[0])
	return true

func _process(delta: float) -> void:
	time += delta
	if time < 0.01:
		return

	if log_file:
		while log_file.get_position() < log_file.get_length():
			var next_line = log_file.get_line()
			terminal.insert_text_at_caret("LOG: %s\n" % next_line)
			terminal.insert_text_at_caret(next_line)


	if not _client and _server.is_connection_available():
		terminal.insert_text_at_caret("Client available!\n")
		_client = _server.take_connection()
		terminal.clear()
		terminal.insert_text_at_caret("Opened connection to MPF.\n")
		terminal.insert_text_at_caret("client connected!\n")
		# var err = _thread.start(self._thread_poll, Thread.PRIORITY_LOW)
		# if err != OK:
		# 	printerr("Error spawining thread: %s" % err)
		# else:
		# 	terminal.insert_text_at_caret("Client connected")
		# set_process(false)

	if not _client:
		time = 0.0
		return

	# if not _client:
	# 	terminal.insert_text_at_caret("no client!")
	# 	return

	var bytes = _client.get_available_bytes()
	while bytes:
		var messages = _client.get_string(bytes)
		terminal.insert_text_at_caret(messages)
		terminal.insert_text_at_caret("\n")
		bytes = _client.get_available_bytes()

	var err = _client.poll()
	var status = _client.get_status()
	# terminal.insert_text_at_caret("no bytes, client_status is %s and error is %s." % [status, err])
	if not status:
		_client.disconnect_from_host()
		_client = null
		self.listen()

	# terminal.insert_text_at_caret(bytes)
	# var data = _client.get_data(bytes)
	# terminal.insert_text_at_caret(data)

	# for message_raw in messages:
	# 	terminal.insert_text_at_caret(message_raw)
	# 	terminal.insert_text_at_caret(message_raw)
	# 	terminal.insert_text_at_caret("\n")

	time = 0.0

func listen() -> void:
	# _thread = Thread.new()
	var err = _server.listen(port)
	if err != OK:
		printerr("Error opening socket: %s" % err)
	terminal.insert_text_at_caret("Server listening on port %s" % port)
	set_process(true)

func _thread_poll(_userdata=null) -> void:
	var _start = Time.get_ticks_msec()
	var delay = 1000.0 /poll_fps
	terminal.insert_text_at_caret("polling....")
	while _client:
		# If the mutex is locked, the system is shutting down
		if not _mutex.try_lock():
			terminal.insert_text_at_caret("mutex locked")
			return
		var bytes = _client.get_available_bytes()
		if not bytes:
			_client.poll()
			terminal.insert_text_at_caret("no bytes, client_status is %s. will delay %sms" % [_client.get_status(), delay])
			OS.delay_msec(delay)
		else:
			call_deferred("add_text", _client.get_string(bytes))
			# terminal.insert_text_at_caret(_client.get_string(bytes))
			# var messages := _client.get_string(bytes).split("\n")
			# for message_raw in messages:
			# 	if message_raw.is_empty():
			# 		continue
			# 	terminal.insert_text_at_caret(message_raw)
			# 	terminal.insert_text_at_caret("\n")
		_mutex.unlock()
	terminal.insert_text_at_caret("out of loop!")

func on_disconnect() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	self.listen()

func stop() -> void:
	_mutex.lock()
	_server.stop()
	if _client:
		_client.disconnect_from_host()
		_client = null
	_mutex.unlock()

	if _thread and _thread.is_started():
		_thread.wait_to_finish()

func add_text(text):
	terminal.insert_text_at_caret(text)
	terminal.insert_text_at_caret("\n")

# func stop():
# 	if timer:
# 		timer.stop()
# 	set_process(false)

# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	if not log_file:
# 		terminal.insert_text_at_caret("no log file, abort")
# 		set_process(false)
# 	time += delta
# 	if time < 0.15:
# 		return
# 	time = 0.0
# 	text_target.insert_text_at_caret("i am output panel")

# 	while log_file.get_position() < log_file.get_length():
# 		var new_line: String = log_file.get_line()
# 		terminal.insert_text_at_caret(new_line)
# 		text_target.insert_text_at_caret(new_line)


func _open_log(log_file_path: String) -> void:
	terminal.insert_text_at_caret("Opening log file at path '%s'" % log_file_path)
	log_file = FileAccess.open(log_file_path, FileAccess.READ)

	timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.autostart = true
	# For some reason adding the timer to the tree enables _process() on this node
	get_tree().get_root().add_child(timer)

	timer.start()
	if not log_file:
		var err = FileAccess.get_open_error()
		if err == Error.ERR_FILE_NOT_FOUND:
			terminal.insert_text_at_caret("log not there yet, retrying")
			await timer.timeout
			terminal.insert_text_at_caret("okay NOW retrying")
			return self._open_log(log_file_path)
		printerr(err)
	timer.stop()
	set_process(true)
	terminal.insert_text_at_caret("Log opening success: %s" % log_file)