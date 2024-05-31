extends Control

func _ready() -> void:
	MPF.server.service.connect(self._on_service)
	self._get_active_switches()

func _on_service(payload: Dictionary) -> void:
	if payload.cmd == "list_switches":
		self._update_active_switches(payload)
		return

	if payload.name != "service_switch_test_start":
		return
	self._get_active_switches()

	var label: String = payload.switch_label.http_unescape()
	$last_switch_label.text = label
	$last_switch_address.text = payload.switch_num.http_unescape()

	var recency = Label.new()
	var prefix: String
	if payload.switch_state == "active":
		prefix = "A"
		$last_switch_state.text = "Active"
	else:
		prefix = "I"
		recency.modulate = Color(1,1,1,0.5)
		$last_switch_state.text = "Inactive"
	recency.text = "[%s] %s" % [prefix, label]
	$recent_switches.add_child(recency)
	while $recent_switches.get_child_count() > 20:
		var switch_to_remove = $recent_switches.get_child(0)
		$recent_switches.remove_child(switch_to_remove)
		switch_to_remove.queue_free()

	# # HACK! Use the start button to exit out of this mode
	if payload.switch_name == "s_credit":
		var e = InputEventKey.new()
		e.scancode = KEY_KP_ENTER
		e.pressed = true
		get_tree().input_event(e)

func _get_active_switches() -> void:
	MPF.server.send_service("list_switches", ["label", "state"])

func _update_active_switches(payload: Dictionary) -> void:
	# Remove the existing children. Used to exclude first, now all.
	while $active_switches.get_child_count() > 0:
		var child_to_remove = $active_switches.get_child(0)
		$active_switches.remove_child(child_to_remove)
		child_to_remove.queue_free()

	for switch in payload.switches:
		if switch[1]:
			var child = Label.new()
			child.text = switch[0]
			$active_switches.add_child(child)
