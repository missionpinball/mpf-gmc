# Copyright 2021 Paradigm Tilt
extends ServicePage


var focused_child

func _ready():
	for child in $TestViews.get_children():
		child.visible = false

func _unhandled_key_input(event):
	if not self.is_focused or event.key_label != -1:
		return

	if event.keycode == KEY_ENTER or event.keycode == KEY_CAPSLOCK:
		# For direct children (not down the tree), send an event
		for c in List.get_children():
			if c.has_focus():
				var focused_name: String = c.name
				MPF.server.send_event("service_trigger&action=%s&sort=false" % focused_name)
				self._update_test_views(focused_name)
				get_window().set_input_as_handled()

	elif focused_child and (event.keycode == KEY_ESCAPE or event.keycode == KEY_CAPSLOCK):
			self.deselect_child()
			get_window().set_input_as_handled()

# A public method so children can de-select themselves
func deselect_child():
	# Move focus from the child back to the selector
	List.get_node(focused_child).grab_focus()
	# Post to MPF, which is too busy listening to events
	MPF.server.send_event("sw_service_esc_active")
	self._update_test_views()

func _update_test_views(focused_name:String = ""):
	focused_child = false
	for child in $TestViews.get_children():
		$TestViews.remove_child(child)
		child.queue_free()
	for menu in List.get_children():
		menu.button_pressed = menu.name == focused_name

	if focused_name:
		focused_child = focused_name
		var child_node = load("res://addons/mpf-gmc/slides/service/%s.tscn" % focused_name).instantiate()
		$TestViews.add_child(child_node)
		child_node.grab_focus()