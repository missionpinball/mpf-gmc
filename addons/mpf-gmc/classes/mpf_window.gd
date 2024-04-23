@tool
class_name MPFWindow extends Control

var displays: Dictionary = {}
var default_display: MPFDisplay

func _ready() -> void:

    MPF.mc.register_window(self)
    self._check_config()
    # In case no default is explicitly defined, track the first one
    var first_display: MPFDisplay
    for display in self.get_children():
        if not display is MPFDisplay:
            continue
        if not first_display:
            first_display = display
        if display.is_default:
            assert(not default_display, "More than one Display cannot be default")
            default_display = display
        displays[display.name] = display
    if not default_display:
        default_display = first_display
    if not Engine.is_editor_hint():
        MPF.server.listen()

func _enter_tree():
    pass

func play_slides(payload: Dictionary) -> void:
    self._play_scene("slide", payload)

func play_widgets(payload: Dictionary) -> void:
    self._play_scene("widget", payload)

func _play_scene(scene_type: String, payload: Dictionary) -> void:
    MPF.log.info("Playing %s with payload %s", [scene_type, payload])
    var dirty_displays = []
    # Strip the settings from the payload to avoid redundant nestings
    var kwargs = payload.duplicate()
    kwargs.erase("settings")
    for name in payload.settings.keys():
        var settings = payload.settings[name]
        var action: String = settings['action']
        if action == "preload":
            if scene_type == "slide":
                MPF.mc.get_slide_instance(name, true)
            elif scene_type == "widget":
                MPF.mc.get_widget_instance(name, true)
            return

        var context = payload.context
        var priority = payload.priority
        var target = settings.get('target')
        var display: MPFDisplay = get_display(target) if target else get_display()
        if scene_type == "slide":
            display.process_slide(name, action, settings, context, priority, kwargs)
        elif scene_type == "widget":
            display.process_widget(name, action, settings, context, priority, kwargs)
        if display not in dirty_displays:
            dirty_displays.append(display)
    for display in dirty_displays:
        display.update_stack(kwargs)

func get_display(display_name: String = "") -> MPFDisplay:
    if not display_name:
        return default_display
    assert(display_name in displays, "Unknown display name '%s'" % display_name)
    return displays[display_name]

func _check_config() -> void:
    if MPF.config and MPF.config.has_section("filter"):
        # Don't show the filter in the editor
        if Engine.is_editor_hint():
            return
        # Check for a filter
        if MPF.config.has_section_key("filter", "filter"):
            var filter_name = MPF.config.get_value("filter", "filter")
            var filter = null
            for c in self.get_node("filters").get_children():
                if c.name == filter_name:
                    filter = c
                    c.show()
                else:
                    c.hide()
            assert(filter != null, "Unknown filter '%s'" % filter_name)
            for prop in ["rows", "columns", "hardness", "color", "spacing"]:
                if MPF.config.has_section_key("filter", prop):
                    filter.material.set_shader_parameter(prop, MPF.config.get_value("filter", prop))
    # For safety, disable all filters
    else:
        self.get_node("filters").hide()
