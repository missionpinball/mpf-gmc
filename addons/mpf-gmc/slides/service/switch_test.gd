extends HBoxContainer

func _ready() -> void:
	MPF.server.service.connect(self._on_service)
	self._get_active_switches()

func _on_service(payload: Dictionary) -> void:
	if payload.cmd == "list_switches":
		self._update_active_switches(payload)
		return

	if payload.name == "service_switch_test_stop":
		var parent = self.get_parent()
		while parent:
			if parent is UtilitiesPage:
				parent.deselect_child()
				break
			parent = parent.get_parent()
		return

	if payload.name != "service_switch_test_start":
		return
	self._get_active_switches()

	# The initial call has empty values, ignore it
	if payload.switch_state == "":
		return

	var label: String = payload.switch_label.uri_decode()
	# If user-friendly labels are not provided, use the key name
	if not label:
		label = payload.switch_name
	$active_test/last_switch_label.text = label
	var addr = payload.switch_num.uri_decode() if typeof(payload.switch_num) == TYPE_STRING else "%s" % payload.switch_num
	$active_test/last_switch_address.text = addr

	var recency = Label.new()
	var prefix: String
	if payload.switch_state == "active":
		prefix = "A"
		$active_test/last_switch_state.text = "Active"
	else:
		prefix = "I"
		recency.modulate = Color(1,1,1,0.5)
		$active_test/last_switch_state.text = "Inactive"
	recency.text = "[%s] %s" % [prefix, label]
	$recent_test/recent_switches.add_child(recency)
	while $recent_test/recent_switches.get_child_count() > 20:
		var switch_to_remove = $recent_test/recent_switches.get_child(0)
		$recent_test/recent_switches.remove_child(switch_to_remove)
		switch_to_remove.queue_free()

func _get_active_switches() -> void:
	# TODO: Get switches that don't have labels
	MPF.server.send_service("list_switches", ["name", "label", "state"])

func _update_active_switches(payload: Dictionary) -> void:
	# Remove the existing children. Used to exclude first, now all.
	while $active_test/active_switches.get_child_count() > 0:
		var child_to_remove = $active_test/active_switches.get_child(0)
		$active_test/active_switches.remove_child(child_to_remove)
		child_to_remove.queue_free()

	for switch in payload.switches:
		if switch[2]:
			var child = Label.new()
			# Use the label if available, otherwise the name
			child.text = switch[1] if switch[1] != "%" else switch[0]
			$active_test/active_switches.add_child(child)
