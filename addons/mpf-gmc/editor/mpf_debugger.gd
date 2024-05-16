@tool

class_name MPFDebuggerPlugin
extends EditorDebuggerPlugin

var output_panel: Control

func _has_capture(prefix):
	# Return true if you wish to handle message with this prefix.
	return prefix == "mpf_log_created"

func _capture(message, data, session_id):
	print("Received message: %s" % message)
	# MPF.process.mpf_log_created.emit(data[0])
	output_panel._open_log(data[0])

func _setup_session(session_id):
	print("Setting up session")
	# Add a new tab in the debugger session UI containing a label.
	var label = Label.new()
	label.name = "MPF Output"
	label.text = "I am a buttface"
	var session = get_session(session_id)
	# Listens to the session started and stopped signals.
	# session.started.connect(func (): print("Session started"))
	# session.stopped.connect(func (): print("Session stopped"))
	# session.add_session_tab(label)
	session.stopped.connect(self._stop_session)

	output_panel = preload("res://addons/mpf-gmc/editor/mpf_output.gd").new()
	output_panel.name = "MPF 4 Realz"

	output_panel.size_flags_vertical = Control.SizeFlags.SIZE_EXPAND_FILL
	output_panel.custom_minimum_size.x = 400
	output_panel.custom_minimum_size.y = 400
	output_panel.initialize()
	session.add_session_tab(output_panel)
	# label.add_child(output_panel)

func _stop_session():
	output_panel.stop()
