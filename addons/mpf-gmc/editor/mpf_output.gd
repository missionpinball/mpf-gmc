@tool
extends Control

var log_file: FileAccess
var log_file_path
var time := 0.0

@export var terminal: TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	push_warning("MPF OUTPUT terminal %s is ready, clearing text." % self)
	terminal.text = "No MPF Log Data."

func _exit_tree() -> void:
	log_file_path = null
	if log_file:
		log_file.close()
		log_file = null

func _on_log_created(message: String, data: Array) -> bool:
	push_warning("MPF OUTPUT terminal %s loading log file at %s" % [self, data[0]])
	terminal.text = ""
	self.log_file = null
	self.log_file_path = data[0]
	return true

func _process(delta: float) -> void:
	time += delta
	if time < 0.05:
		return

	if log_file:
		#push_warning(" - log file position is %s out of length %s" % [log_file.get_position(), log_file.get_length()])
		while log_file.get_position() < log_file.get_length():
			var next_line = log_file.get_line()
			terminal.insert_text_at_caret("%s\n" % next_line)
		time = 0.0
	elif log_file_path:
		if time > 1:
			self._open_log()
			time = 0.0
		return
	time = 0.0


func _open_log() -> void:

	log_file = FileAccess.open(log_file_path, FileAccess.READ)
	if not log_file:
		var err = FileAccess.get_open_error()
		if err != Error.ERR_FILE_NOT_FOUND:
			terminal.insert_text_at_caret("Error opening log file: %s\n" % err)
