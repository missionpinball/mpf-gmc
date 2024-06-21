# Copyright 2021 Paradigm Tilt

extends MPFSlide

@export var highlight_color: Color


const triggers = ["service_button",
"service_switch_test_start", "service_switch_test_stop",
"service_coil_test_start", "service_coil_test_stop",
"service_light_test_start", "service_light_test_stop"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MPF.server.service.connect(self._on_service)
	for trigger in triggers:
		MPF.server._send("register_trigger?event=%s" % trigger)
	# Remove any service pages with no content
	for i in $TabContainer.get_child_count():
		var c = $TabContainer.get_child(i)
		if c is ServicePage and not c.has_settings():
			$TabContainer.set_tab_hidden(i, true)
	focus()

func _exit_tree() -> void:
	for trigger in triggers:
		MPF.server._send("remove_trigger?event=%s" % trigger)

func focus():
	# Use call_deferred to grab focus to ensure tree stability
	$TabContainer.grab_focus.call_deferred()
	$TabContainer.set("custom_colors/font_color_fg", highlight_color)

func _on_service(payload):
	if payload.has("button"):
		self._on_button(payload)

func _on_button(payload):
	if not payload.has("button"):
		return

	var inputEvent = InputEventKey.new()
	inputEvent.pressed = true
	# Set a special key label to prevent keyboards during development
	inputEvent.key_label = -1
	inputEvent.keycode = {
		"DOWN": KEY_DOWN,
		"UP": KEY_UP,
		"ENTER": KEY_ENTER,
		"ESC": KEY_ESCAPE,
		"PAGE_LEFT": KEY_PAGEUP,
		"PAGE_RIGHT": KEY_PAGEDOWN,
		"START": KEY_BACKSPACE,
		"TOGGLE": KEY_CAPSLOCK,
	}[payload.button]
	Input.parse_input_event(inputEvent)

func _unhandled_key_input(event):
	if event.key_label != -1:
		return

	if $TabContainer.has_focus():
		if event.keycode == KEY_ESCAPE:
			$TabContainer.select_previous_available()
			get_window().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			$TabContainer.select_next_available()
			get_window().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			self.select_page()
			get_window().set_input_as_handled()
	elif event.keycode == KEY_BACKSPACE:
		self.focus()
		# Reset the focus settings of the child page
		var page = $TabContainer.get_child($TabContainer.current_tab)
		page.unfocus()
		get_window().set_input_as_handled()

func select_page():
	# Last tab is always exit
	if $TabContainer.current_tab == $TabContainer.get_tab_count() - 1:
		MPF.server.send_event("service_trigger&action=service_exit")
		return
	var target = $TabContainer.get_child($TabContainer.current_tab)
	target.focus()

	$TabContainer.set("custom_colors/font_color_fg", null)
