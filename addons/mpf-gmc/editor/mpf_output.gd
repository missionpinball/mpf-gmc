@tool
extends Control

var log_file
var time := 0.0
# @onready var text_target: TextEdit = self.get_node("VBoxContainer").get_node("TextEdit")
var text_target
var timer: Timer


@export var terminal: TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	terminal.text = "No MPF Log Data."

func _exit_tree() -> void:
	if log_file:
		log_file.close()

func _on_log_created(message: String, data: Array) -> bool:
	terminal.text = ""
	self._open_log(data[0])
	return true

func _process(delta: float) -> void:
	time += delta
	if time < 0.05:
		return

	if log_file:
		while log_file.get_position() < log_file.get_length():
			var next_line = log_file.get_line()
			terminal.insert_text_at_caret("%s\n" % next_line)
	time = 0.0


func _open_log(log_file_path: String) -> void:
	terminal.insert_text_at_caret("Opening MPF Log at '%s'\n" % log_file_path)
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
			await timer.timeout
			return self._open_log(log_file_path)
		terminal.insert_text_at_caret("Error opening log file: %s\n" % err)
	timer.stop()
