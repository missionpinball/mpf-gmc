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
	text_target = TextEdit.new()
	text_target.text = "Buttface McGee"
	text_target.size_flags_vertical = SizeFlags.SIZE_EXPAND_FILL
	self.add_child(text_target)
	set_process(false)

func stop():
	if timer:
		timer.stop()
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not log_file:
		print("no log file, abort")
		set_process(false)
	time += delta
	if time < 0.15:
		return
	time = 0.0
	text_target.insert_text_at_caret("i am output panel")

	while log_file.get_position() < log_file.get_length():
		var new_line: String = log_file.get_line()
		print(new_line)
		text_target.insert_text_at_caret(new_line)


func _open_log(log_file_path: String) -> void:
	print("Opening log file at path '%s'" % log_file_path)
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
			print("log not there yet, retrying")
			await timer.timeout
			print("okay NOW retrying")
			return self._open_log(log_file_path)
		printerr(err)
	timer.stop()
	set_process(true)
