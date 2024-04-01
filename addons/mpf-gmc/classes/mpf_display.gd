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
    self._slide_stack.append(slide)
    self._slides.add_child(slide)
    self._update_stack()
    return slide

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
    if not self._slide_stack:
        return
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
        else:
            self._slides.move_child(s, idx)
    var new_slide = self._slide_stack[-1]
    if new_slide != self._current_slide:
        if self._current_slide:
            MPF.server.send_event("slide_%s_inactive" % self._current_slide.key)
            if self._current_slide not in self._slide_stack:
                MPF.server.send_event("slide_%s_removed" % self._current_slide.key)
        MPF.server.send_event("slide_%s_active" % new_slide.key)
        self._current_slide = new_slide

func _on_clear(mode_name) -> void:
    self._slide_stack = self._slide_stack.filter(
        func(slide): return slide.context != mode_name
    )
    # TODO: For the remaining slides, call clear to remove any
    # widgets added by the cleared mode
    self._update_stack()
