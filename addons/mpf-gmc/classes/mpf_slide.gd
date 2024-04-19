@tool
class_name MPFSlide
extends MPFSceneBase

var _widgets: Node2D
var _updaters: Array[Node2D] = []


func initialize(name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    # The node name attribute is the name of the root node, which could be
    # anything or case-sensitive. Set an explicit key instead, using the name.
    super(name, settings, context, priority, kwargs)
    print("Slide is being initialized")
    # Wait for the child variables to initialize themselves
    await self.ready
    print("slide is ready, proceeding with init")
    self.action_update(settings, kwargs)

func _ready() -> void:
    print("slide is ready")

func _enter_tree():
    print("slide is entering tree")

func register_updater(node: Node2D):
    if self._updaters.find(node) == -1:
        self._updaters.append(node)

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

func action_update(settings: Dictionary, kwargs: Dictionary = {}):
    for c in self._updaters:
        c.update(settings, kwargs)

func action_remove(widget: Node) -> void:
    self._widgets.remove_child(widget)
    widget.queue_free()

func clear(context_name):
    if not self._widgets:
        return
    for w in self._widgets.get_children():
        if w.context == context_name:
            self.action_remove(w)
