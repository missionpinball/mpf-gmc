@tool
## A plugin to attach the Debugger session to the MPF Output Panel
class_name MPFDebuggerPlugin
extends EditorDebuggerPlugin

var editor_panel

func _has_capture(prefix):
	# Return true if you wish to handle message with this prefix.
	return prefix == "mpf_log_created"

func _capture(message, data, session_id):
	if editor_panel:
		editor_panel._on_log_created(message, data)

func attach_panel(panel: Object):
	editor_panel = panel