@tool
class_name MPFSlide
extends MPFSceneBase

var _widgets: Node2D

func process_widget(widget_name: String, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    if not self._widgets:
        self._widgets = Node2D.new()
        self.append_child(self._widgets)
    self.process_action(widget_name, action, settings, context, priority, kwargs)

func action_play(widget_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> MPFWidget:
    var widget = MPF.mc.get_widget(widget_name)
    assert(widget is MPFWidget, "Widget scenes must use (or extend) the MPFWidget script on the root node.")
    widget.initialize(widget_name, settings, context, priority, kwargs)
    self._widgets.add_child(widget)
    return widget

func action_remove(widget: MPFWidget) -> void:
    self._widgets.remove_child(widget)
    widget.queue_free()
