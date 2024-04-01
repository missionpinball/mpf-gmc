@tool
class_name MPFSlide
extends MPFSceneBase

var _widgets: Node2D

func process_widget(widget_name: String, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    if not self._widgets:
        self._widgets = Node2D.new()
        self.add_child(self._widgets)
    self.process_action(widget_name, self._widgets.get_children(), action, settings, context, priority, kwargs)

func action_play(widget_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> MPFWidget:
    var widget = MPF.mc.get_widget_instance(widget_name)
    assert(widget is MPFWidget, "Widget scenes must use (or extend) the MPFWidget script on the root node.")
    widget.initialize(widget_name, settings, context, priority, kwargs)
    self._widgets.add_child(widget)
    return widget

func action_remove(widget: Node) -> void:
    self._widgets.remove_child(widget)
    widget.queue_free()

func clear(context_name):
    if not self._widgets:
        return
    for w in self._widgets.get_children():
        if w.context == context_name:
            self.action_remove(w)
