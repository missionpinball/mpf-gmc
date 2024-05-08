extends Control

func _enter_tree() -> void:
	push_error("Uh hoh here we go")
	$VBoxContainer/Status.text = "I AM A LOG BOX"
	$VBoxContainer/LogLevel.item_selected.connect(self.set_log_level)
	$VBoxContainer/Label.text = "buttface"

func set_log_level(index: int) -> void:
	push_error("this is at hing")
	var id = $VBoxContainer/LogLevel.get_item_id(index)
	$VBoxContainer/Status.text = "Setting log level to %s" % id
	MPF.log.setLevel(id)
	MPF.config.set_value("logging", "global", id)