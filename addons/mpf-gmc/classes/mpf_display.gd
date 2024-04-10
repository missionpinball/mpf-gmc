@tool
class_name MPFDisplay
extends MPFSceneBase


@export var is_default: bool = false
@export var initial_slide: PackedScene
# The slide stack is an array of slide nodes that are sorted by priority
var _slide_stack: Array = []
# The slides node is the parent container for the slide nodes rendered in the tree
var _slides: Node2D
var _current_slide: MPFSlide
# The queue of slides waiting to be played
var _queue: Array = []

func _ready() -> void:
    self._slides = Node2D.new()
    self.add_child(self._slides)
    if not self.initial_slide:
        return
    # The initial slide will be added as a child but not in the stack, so when
    # the stack is filled and calculated the initial will be removed
    self._slides.add_child(self.initial_slide.instantiate())
    MPF.server.connect("clear", self._on_clear)

func process_slide(slide_name: String, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    self.process_action(slide_name, self._slide_stack, action, settings, context, priority, kwargs)

func process_widget(widget_name: String, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    var slide = self.get_slide(settings.get('slide'))
    # The requested slide may not exist
    if not slide:
        return
    slide.process_widget(widget_name, action, settings, context, priority, kwargs)

func action_play(slide_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> MPFSlide:
    var slide = MPF.mc.get_slide_instance(slide_name)
    assert(slide is MPFSlide, "Slide scenes must use (or extend) the MPFSlide script on the root node.")
    slide.initialize(slide_name, settings, context, priority, kwargs)
    if settings.get("queue"):
        self._manage_queue(settings['queue'])
    self._slide_stack.append(slide)
    self._slides.add_child(slide)
    if kwargs.get("update_stack", true):
        self._update_stack()
    return slide

func action_queue(action: String, slide_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}):
    if settings.get("queue"):
        self._manage_queue(settings['queue'])
    var queue_entry = {
        "key": settings['key'] if settings.get('key') else slide_name,
        "slide_name": slide_name,
        "settings": settings,
        "context": context,
        "priority": priority,
        "kwargs": kwargs,
        "expiration": 0
    }
    # Check for an expiration time
    if settings.get("max_queue_time"):
        queue_entry["expiration"] = Time.get_ticks_msec() + (1000 * settings['max_queue_time'])

    # Add this slide to the queue
    if not self._queue.size():
        self._queue.append(queue_entry)
    elif action == "queue":
        self._queue.push_back(queue_entry)
    else:
        self._queue.insert(1, queue_entry)
    # If there was no queue before or this in as immediate action, process the queue
    if self._queue.size() == 1 or action == "queue_immediate":
        return self._process_queue()

func update_stack():
    self._update_stack()

func action_remove(slide) -> void:
    self._slide_stack.erase(slide)
    self._update_stack()

func get_slide(slide_name):
    if not slide_name:
        return self._current_slide
    for s in self._slide_stack:
        if s.key == slide_name:
            return s

func _update_stack() -> void:
    # Sort the stack by priority
    self._slide_stack.sort_custom(
        func(a: MPFSlide, b: MPFSlide): return a.priority < b.priority
    )
    # Update the children, rearranging and removing as necessary
    for s in self._slides.get_children():
        var idx = self._slide_stack.find(s)
        if idx == -1:
            self._slides.remove_child(s)
            s.queue_free()
            # If this is in the queue, remove it as well
            if self._queue and s.key == self._queue[0].key:
                self._queue.pop_front()
                var is_queue_changed = self._process_queue()
                # Restart this update with the new slide from the queue
                if is_queue_changed:
                    return self._update_stack()
        else:
            self._slides.move_child(s, idx)

    if not self._slide_stack:
        self._current_slide = null
        return

    var new_slide = self._slide_stack[-1]
    if new_slide != self._current_slide:
        if self._current_slide:
            MPF.server.send_event("slide_%s_inactive" % self._current_slide.key)
            if self._current_slide not in self._slide_stack:
                MPF.server.send_event("slide_%s_removed" % self._current_slide.key)
        MPF.server.send_event("slide_%s_active" % new_slide.key)
        self._current_slide = new_slide

func _manage_queue(action: String) -> void:
    if action == "clear":
        self._queue.resize(1)
    elif action == "clear_immediate":
        self._queue.clear()

func _process_queue():
    if not self._queue.size():
        return
    while self._queue.size():
        var s = self._queue[0]
        if s["expiration"] and s["expiration"] < Time.get_ticks_msec():
            self._queue.pop_front()
        else:
            self.process_slide(s["slide_name"], "play", s["settings"], s["context"], s["priority"], s["kwargs"])
            return

func _on_clear(context_name) -> void:
    # Filter all slides with the given context
    self._slide_stack = self._slide_stack.filter(
        func(slide): return slide.context != context_name
    )
    self._update_stack()
    # For the remaining slides, clear out any widgets from that context
    for s in self._slide_stack:
        s.clear(context_name)
