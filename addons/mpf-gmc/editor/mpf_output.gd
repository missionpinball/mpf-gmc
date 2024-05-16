@tool
extends Control

var log_file
var time := 0.0
# @onready var text_target: TextEdit = self.get_node("VBoxContainer").get_node("TextEdit")
var text_target
var timer: Timer

# Called when the node enters the scene tree for the first time.
func initialize():
	print("Hello I'm mpf output panel")
	MPF.process.mpf_log_created.connect(self._open_log)
	EngineDebugger.register_message_capture("mpf_log_created", self._on_log_created)
	text_target = TextEdit.new()
	text_target.text = "Buttface McGee"
	text_target.size_flags_vertical = SizeFlags.SIZE_EXPAND_FILL
	self.add_child(text_target)
	set_process(false)
	print("is there a tree? %s" % get_tree())

func stop():
	print("STOP THIS MADNESS!")
	if timer:
		timer.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not log_file:
		print("no log file, abort")
		set_process(false)
	time += delta
	if time < 0.25:
		return
	time = 0.0
	print("PROCESS ME")
	text_target.insert_text_at_caret("i am output panel")

func _process_log():
	print("Processing log...")
	while log_file.get_position() < log_file.get_length():
		var new_line: String = log_file.get_line()
		print(new_line)
		text_target.insert_text_at_caret(new_line)

func _on_log_created(message: String, data: Array) -> bool:
	print("I see a log created!!")
	return true

func _open_log(log_file_path: String) -> void:
	print("Opening log file at path '%s'" % log_file_path)
	log_file = FileAccess.open(log_file_path, FileAccess.READ)
	# if not timer:
	# 	timer = get_tree().create_timer(0.25)

	timer = Timer.new()
	timer.wait_time = 0.25
	timer.one_shot = false
	timer.autostart = true
	get_tree().get_root().add_child(timer)

	print(timer)
	timer.start()
	if not log_file:
		var err = FileAccess.get_open_error()
		if err == Error.ERR_FILE_NOT_FOUND:
			print("log not there yet, retrying")
			await timer.timeout
			print("okay NOW retrying")
			return self._open_log(log_file_path)
		printerr(err)
	print("FONUD A LOG!")
	timer.timeout.connect(self._process_log)
	set_process(true)
