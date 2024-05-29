@tool
## A plugin to attach the Debugger session to the MPF Output Panel
extends EditorDebuggerPlugin

var editor_panel

func _has_capture(prefix):
	# Return true if you wish to handle message with this prefix.
	return prefix == "mpf_log_created"

func _capture(message, data, _session_id):
	if editor_panel:
		editor_panel.open_log_message(message, data)
	return true

func _setup_session(session_id: int) -> void:
	var session = self.get_session(session_id)
	session.started.connect(self._on_session_started)
	session.stopped.connect(self._on_session_stopped)

func _on_session_started():
	if editor_panel:
		editor_panel.session_started()

func _on_session_stopped():
	if editor_panel:
		editor_panel.session_stopped()

func attach_panel(panel: Object):
	editor_panel = panel
