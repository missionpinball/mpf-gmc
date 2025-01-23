class_name MPFWindow extends Control

## Root node for the entire GMC display screen. Hosts one or more MPFDisplay child nodes for rendering slides.

var displays: Dictionary = {}
var default_display: MPFDisplay

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		if MPF.get_config_value("gmc", "fullscreen", false):
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _ready() -> void:
	# Force the window dimensions to match the project settings
	self.custom_minimum_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	self.custom_minimum_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")

	MPF.media.register_window(self)
	self._check_config()
	if not Engine.is_editor_hint():
		MPF.server.listen()

func play_slides(payload: Dictionary) -> void:
	self._play_scene("slide", payload)

func play_widgets(payload: Dictionary) -> void:
	self._play_scene("widget", payload)

func _play_scene(scene_type: String, payload: Dictionary) -> void:
	var dirty_displays = []
	# Strip the settings from the payload to avoid redundant nestings
	var kwargs = payload.duplicate()
	kwargs.erase("settings")
	for n in payload.settings.keys():
		var settings = payload.settings[n]
		var action: String = settings['action']
		if action == "preload":
			if scene_type == "slide":
				MPF.media.get_slide_instance(n, true)
			elif scene_type == "widget":
				MPF.media.get_widget_instance(n, true)
			return

		var context = payload.context
		var priority = payload.priority
		var target = settings.get('target')
		var display: MPFDisplay = get_display(target) if target else get_display()
		if scene_type == "slide":
			display.process_slide(n, action, settings, context, priority, kwargs)
		elif scene_type == "widget":
			display.process_widget(n, action, settings, context, priority, kwargs)
		if display not in dirty_displays:
			dirty_displays.append(display)
	for display in dirty_displays:
		display.update_stack(kwargs)

func get_display(display_name: String = "") -> MPFDisplay:
	if not display_name:
		return default_display
	assert(display_name in displays, "Unknown display name '%s'" % display_name)
	return displays[display_name]

func register_display(display: MPFDisplay) -> void:
	# Register this display by name
	self.displays[display.name] = display
	# If no display is registered default, the first one becomes default
	if not self.default_display:
		self.default_display = display
	elif display.is_default:
		# If one is flagged as default and the first one is not, reassign
		if not self.default_display.is_default:
			self.default_display = display
		else:
			assert(false, "More than one Display cannot be default")
	MPF.log.info("Registered display %s", display)

func _check_config() -> void:
	var filter_parent = self.get_node_or_null("filters")
	if MPF.has_config_section("filter"):
		assert(filter_parent != null, "gmc.cfg has a [filters] section but MPFWindow does not have a 'filters' child")
		# Don't show the filter in the editor
		if Engine.is_editor_hint():
			return
		# Check for a filter
		var filter_name = MPF.get_config_value("filter", "filter", false)
		if filter_name:
			var filter = null
			for c in filter_parent.get_children():
				if c.name == filter_name:
					filter = c
					c.show()
				else:
					c.hide()
			# If the filter is a resource, look it up
			if not filter and filter_name.begins_with("res://"):
				filter = filter_parent.get_node("custom")
				filter.material.shader = load(filter_name)
				filter.show()

			assert(filter != null, "Unknown filter '%s'" % filter_name)
			for prop in MPF.get_config_keys("filter"):
				if prop == "filter":
					continue
				filter.material.set_shader_parameter(prop, MPF.get_config_value("filter", prop))
			filter_parent.show()
	# For safety, disable all filters
	elif filter_parent:
		filter_parent.hide()
