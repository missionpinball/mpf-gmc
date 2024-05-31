# Copyright 2021 Paradigm Tilt

extends Node2D

export (Color) var highlight_color


const triggers = ["service_button",
"service_switch_test_start", "service_switch_test_stop",
"service_coil_test_start", "service_coil_test_stop",
"service_light_test_start", "service_light_test_stop"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  Server.connect("service", self, "_on_service")
  for trigger in triggers:
    Server._send("register_trigger?event=%s" % trigger)
  focus()

func _exit_tree() -> void:
  for trigger in triggers:
    Server._send("remove_trigger?event=%s" % trigger)

func focus():
  $TabContainer.grab_focus()
  $TabContainer.set("custom_colors/font_color_fg", highlight_color)

func _on_service(payload):
  if payload.has("button"):
    self._on_button(payload)

func _on_button(payload):
  if not payload.has("button"):
    return

  var inputEvent = InputEventKey.new()
  inputEvent.pressed = true
  inputEvent.scancode = {
    "DOWN": KEY_HOME,
    "UP": KEY_END,
    "ENTER": KEY_DELETE,
    "ESC": KEY_ENTER,
    "PAGE_LEFT": KEY_PAGEUP,
    "PAGE_RIGHT": KEY_PAGEDOWN
  }[payload.button]
  get_tree().input_event(inputEvent)

func _input(event):
  if event is InputEventKey:
    if $TabContainer.has_focus():
      if event.is_action_pressed("ui_left"):
        self.select_tab(-1)
      elif event.is_action_pressed("ui_right"):
        self.select_tab(1)
      elif event.is_action_pressed("ui_select"):
        self.select_page()
    elif event.is_action_pressed("ui_accept"):
      self.focus()
      # Reset the focus settings of the child page
      var page = $TabContainer.get_child($TabContainer.current_tab)
      page.unfocus()

func select_tab(direction: int):
  var next = $TabContainer.current_tab + direction
  if next >= 0 and next < $TabContainer.get_tab_count():
    $TabContainer.current_tab = next

func select_page():
  # Last tab is always exit
  if $TabContainer.current_tab == $TabContainer.get_tab_count() - 1:
    Server.send_event("service_trigger&action=service_exit")
    return
  var target = $TabContainer.get_child($TabContainer.current_tab)
  target.focus()

  $TabContainer.set("custom_colors/font_color_fg", null)
