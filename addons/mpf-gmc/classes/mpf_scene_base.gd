@tool
class_name MPFSceneBase
extends Node2D

var priority: int = 0
var context: String
var key: String
var _variables: Array[Node]

func initialize(key: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    # The "name" is the name of the root node, which could be
    # anything or case-sensitive. Set an explicit key instead.
    self.key = key
    self.priority = settings['priority'] + priority if settings['priority'] else priority
    self.context = context

    self._variables = MPF.util.find_variables(self)
    self.update(settings, kwargs)

func update(settings: Dictionary, kwargs: Dictionary = {}) -> void:
    for c in self._variables:
        c.update(settings, kwargs)

func process_action(child_name: String, children: Array, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    var child: MPFSceneBase
    for c in children:
        if c.key == child_name:
            child = c
            break
    match action:
        "play":
            if not child:
                child = self.action_play(child_name, settings, context, priority, kwargs)
        "remove":
            if child:
                self.action_remove(child)
        "update":
            if child:
                child.update(settings, kwargs)
        "method":
            if child and child.has_method(settings.method):
                var callable = Callable(child, settings.method)
                callable.call(settings, kwargs)
    if child and settings.expire:
        self._create_expire(child, settings.expire)

func action_play(child_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}):
    assert(false, "Method 'action_play' must be overridden in child classes of MPFSceneBase")

func action_remove(widget: Node) -> void:
    assert(false, "Method 'action_remove' must be overridden in child classes of MPFSceneBase")

func _create_expire(child: MPFSceneBase, expiration_secs: float) -> void:
    var timer = Timer.new()
    timer.wait_time = expiration_secs
    timer.one_shot = true
    timer.autostart = true
    timer.timeout.connect(self._on_expire.bind(child, timer))
    self.add_child(timer)

func _on_expire(child: MPFSceneBase, timer: Timer) -> void:
    self.remove_child(timer)
    timer.queue_free()
    self.action_remove(child)
