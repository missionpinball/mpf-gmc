extends MPFSlide

var ServerStatus = MPF.server.ServerStatus

# Called when the node enters the scene tree for the first time.
func _ready():
	for c in [
		$CenterContainer/VBoxContainer/status_main,
		$CenterContainer/VBoxContainer/status_sub,
		$CenterContainer/VBoxContainer/error_main,
		$CenterContainer/VBoxContainer/error_sub,
	]:
		c.hide()
	MPF.server.status_changed.connect(self._on_status)
	self._on_status(MPF.server.status)

func _on_status(new_status):
	var error_node = $CenterContainer/VBoxContainer/error_main
	var status_node = $CenterContainer/VBoxContainer/status_main
	var target_child: Node
	var message: String
	if new_status == ServerStatus.ERROR:
		target_child = error_node
		message = "Error: Unable to connect to MPF"
		status_node.hide()
	else:
		target_child = status_node
		error_node.hide()
		match new_status:
			ServerStatus.WAITING:
				message = "Waiting for MPF..."
			ServerStatus.LAUNCHING:
				message = "Launching MPF..."
			ServerStatus.CONNECTED:
				message = "Connected to MPF"
			ServerStatus.IDLE:
				message = ""
	target_child.text = message
	target_child.show()
