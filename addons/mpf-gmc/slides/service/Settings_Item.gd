# Copyright 2021 Paradigm Tilt

extends HBoxContainer
class_name SettingsItem

@export var title: String
@export var variable: String
@export var options: Dictionary
@export var loop: bool = false
@export var selected_value = 0
@export var default: int

var callback
var is_focused := false
var is_option_focused := false

# TODO: Find a better way to make programattic for different service arrangements
const IS_TOGGLE_STYLE: bool = false

func populate(setting=null):
	# Accept a setting object from Game.settings as init values
	if not setting:
		push_error("No setting provided when instantiating Settings_Item.")
		return
	self.variable = setting.variable
	self.title = setting.label
	self.default = setting.default
	if setting.get("options"):
		self.options = setting["options"]
	# Look for a custom value in machine vars
	if MPF.game.machine_vars.has(setting.variable):
		self.selected_value = MPF.game.machine_vars[setting.variable]
	else:
		self.selected_value = self.default

func _ready() -> void:
	self.focus_entered.connect(self._focus_entered)
	self.focus_exited.connect(self._focus_exited)
	self.ready()

# Native methods like _ready() cannot be overridden in subclasses.
# Use a new public method instead
func ready():
	$Setting.text = " %s" % title
	if callback:
		$Option.visible = false
	else:
		# Parser will convert boolean keys to strings, revert back
		if typeof(selected_value) == TYPE_BOOL:
			if selected_value == true:
				selected_value = 1
			elif selected_value == false:
				selected_value = 0
		# Parser will convert "None" to null. Re-vert back
		assert(selected_value in options, "Setting %s has no option for selected value %s. Available options: %s" % [title, selected_value, options])
		if options[selected_value] == null:
			options[selected_value] = "None"
		$Option.text = options[selected_value]
	set_option_text_color()

func _focus_entered() -> void:
	self.is_focused = true
	$Setting.button_pressed = true

func _focus_exited() -> void:
	# If focus is moving to this item's option, preserve focus
	if not is_option_focused:
		self.is_focused = false
		$Setting.button_pressed = false

func _input(event: InputEvent) -> void:
	if not event.is_class("InputEventKey") or event.key_label != -1:
		return
	if not self.is_focused:
		return

	# If this is a toggle event, move focus in/out of the option
	if IS_TOGGLE_STYLE:
		if event.keycode == KEY_CAPSLOCK:
			get_window().set_input_as_handled()
			if self.has_focus():
				is_option_focused = true
				if callback:
					callback.call_func()
				else:
					$Option.grab_focus()
					self.set_setting_background_color(true)
			else:
				self.grab_focus()
				self.set_setting_background_color(false)
				is_option_focused = false
				self.save()
		elif is_option_focused:
			if event.keycode == KEY_ESCAPE:
				get_window().set_input_as_handled()
				select_option(-1)
			elif event.keycode == KEY_ENTER:
				get_window().set_input_as_handled()
				select_option(1)
	# If this is not toggle style, left and right hit the options directly
	else:
		if event.keycode == KEY_ESCAPE:
			get_window().set_input_as_handled()
			select_option(-1)
		elif event.keycode == KEY_ENTER:
			get_window().set_input_as_handled()
			select_option(1)

func save() -> void:
	MPF.server.send_event("service_trigger&action=setting&variable=%s&value=%s" % [variable, selected_value])

func select_option(direction: int = 0) -> void:
	var keys = options.keys()
	var next: int = (keys.find(selected_value) + direction) if direction else 0

	# Allow some options to loop back around on left/right
	if loop:
		# Default Godot modulo allows negatives, so use posmod instead
		next = posmod(next, keys.size())
	if next >= 0 and next < keys.size():
		selected_value = keys[next]
		$Option.text = options[selected_value]
		set_option_text_color()

func set_option_text_color() -> void:
	var color := Color(1,1,1,1) if selected_value == default else Color(0.98,0.34,0,1)
	$Option.set("theme_override_colors/font_color", color)

func set_setting_background_color(is_invoked: bool) -> void:
	if not is_invoked:
		$Setting.add_stylebox_override("pressed", null)
		return
	# Steal the "hover" stylebox, for convenience
	$Setting.add_stylebox_override("pressed", $Setting.get_stylebox("hover"))

func _to_string() -> String:
	return "<SettingsItem:%s>" % variable
