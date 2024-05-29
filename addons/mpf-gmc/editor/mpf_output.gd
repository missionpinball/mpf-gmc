@tool
extends Control

var log_file: FileAccess
var log_file_path
var time := 0.0
var is_stopping: bool = false
var filter_text
@onready var full_text: PackedStringArray = PackedStringArray()

@export var terminal: TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	terminal.text = "MPF log output will appear here after an MPF session is run."
	filter_text = null
	$VBoxContainer/LineEdit.text_changed.connect(self._on_filter_changed)
	set_process(false)

func _exit_tree() -> void:
	log_file_path = null
	if log_file:
		log_file.close()
		log_file = null

func session_started() -> void:
	terminal.text = ""
	self.log_file = null
	self.log_file_path = null

func session_stopped() -> void:
	self.is_stopping = true

func open_log_message(_message: String, data: Array):
	terminal.text = ""
	self.log_file = null
	self.log_file_path = data[0]
	set_process(true)

func _process(delta: float) -> void:
	time += delta
	if time < 0.05:
		return

	if log_file:
		while log_file.get_position() < log_file.get_length():
			var next_line = log_file.get_line() + "\n"
			full_text.append(next_line)
			if (not self.filter_text) or (self.filter_text in next_line):
				terminal.insert_text_at_caret(next_line)
		if is_stopping:
			set_process(false)
			is_stopping = false
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

func _on_filter_changed(new_text: String) -> void:
	if new_text:
		self.filter_text = new_text
	else:
		self.filter_text = null
	self._refresh_text()

func _refresh_text():
	terminal.text = ""
	for line in self.full_text:
		if (not self.filter_text) or (self.filter_text in line):
			terminal.insert_text_at_caret(line)
