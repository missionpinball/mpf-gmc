# Copyright 2021 Paradigm Tilt

extends MPFSlide

@export var highlight_color: Color
@onready var tabRow = $MarginContainer/TabContainer

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
	for i in tabRow.get_child_count():
		var c = tabRow.get_child(i)
		if c is ServicePage and not c.has_settings():
			tabRow.set_tab_hidden(i, true)
	focus()

func _exit_tree() -> void:
	for trigger in triggers:
		MPF.server._send("remove_trigger?event=%s" % trigger)

func focus():
	# Use call_deferred to grab focus to ensure tree stability
	tabRow.grab_focus.call_deferred()
	tabRow.set("theme_override_colors/font_selected_color", highlight_color)

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

func _input(event):
	# Ignore actual key inputs, only manage artificial ones triggered
	# by BCP commands. This ensures that menu behavior is accurate for
	# hardware-connected switches and is not using the keyboard.
	if not event.is_class("InputEventKey") or event.key_label != -1:
		return

	# Last tab is always exit
	var is_exiting = tabRow.current_tab == tabRow.get_tab_count() - 1
	if tabRow.has_focus():
		if event.keycode == KEY_ESCAPE:
			get_window().set_input_as_handled()
			tabRow.select_previous_available()
		elif event.keycode == KEY_ENTER:
			get_window().set_input_as_handled()
			tabRow.select_next_available()
		elif event.keycode == KEY_DOWN and not is_exiting:
			get_window().set_input_as_handled()
			self.select_page()
		elif event.keycode == KEY_BACKSPACE and is_exiting:
			get_window().set_input_as_handled()
			self.exit_service()
	elif event.keycode == KEY_BACKSPACE:
		get_window().set_input_as_handled()
		self.focus()
		# Reset the focus settings of the child page
		var page = tabRow.get_child(tabRow.current_tab)
		page.unfocus()

func select_page():
	var target = tabRow.get_child(tabRow.current_tab)
	target.focus()
	tabRow.set("theme_override_colors/font_selected_color", null)

func exit_service():
	MPF.server.send_event("service_trigger&action=service_exit")
