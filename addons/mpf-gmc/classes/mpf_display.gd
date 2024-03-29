@tool
class_name MPFDisplay extends Node2D


@export var is_default: bool = false
@export var initial_slide: PackedScene
var _slide_stack = []
var _timers = []

func _ready() -> void:
    if not self.initial_slide:
        return
    self.add_child(self.initial_slide.instantiate())
    MPF.server.connect("clear", self._on_clear)


func process_slide(slide_name: String, action: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    # See if this slide already exists
    var slide: MPFSlide
    for s in _slide_stack:
        if s.key == slide_name:
            slide = s
            break
    match action:
        "play":
            # Don't play a slide that's already there
            if not slide:
                slide = self.play_slide(slide_name, settings, context, priority, kwargs)
        "remove":
            if slide:
                self.remove_slide(slide)
        "update":
            if slide:
                slide.update(settings, kwargs)
        "method":
            if slide and slide.has_method(settings.method):
                var callable = Callable(slide, settings.method)
                callable.call(settings, kwargs)
    if slide and settings.expire:
        var timer = Timer.new()
        timer.wait_time = float(settings.expire)
        timer.one_shot = true
        timer.autostart = true
        timer.timeout.connect(self._on_expire.bind(slide, timer))
        self.add_child(timer)


func play_slide(slide_name: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> MPFSlide:
    var slide = MPF.mc.get_slide(slide_name)
    assert(slide is MPFSlide, "Slide scenes must use the MPFSlide script on the root node.")
    slide.initialize(slide_name, settings, context, priority, kwargs)
    self._slide_stack.append(slide)
    self.add_child(slide)
    self._update_stack()
    return slide

func remove_slide(slide) -> void:
    self._slide_stack.erase(slide)
    self._update_stack()

func _update_stack() -> void:
    # Sort the stack by priority
    self._slide_stack.sort_custom(
        func(a: Node, b: Node): return a.priority < b.priority
    )
    # Update the children, rearranging and removing as necessary
    for s in self.get_children():
        var idx = self._slide_stack.find(s)
        if idx == -1:
            self.remove_child(s)
            s.queue_free()
        else:
            self.move_child(s, idx)

func _on_clear(mode_name) -> void:
    self._slide_stack = self._slide_stack.filter(
        func(slide): return slide.context != mode_name
    )
    # TODO: For the remaining slides, call clear to remove any
    # widgets added by the cleared mode
    self._update_stack()

func _on_expire(slide: MPFSlide, timer: Timer) -> void:
    self.remove_child(timer)
    self.remove_slide(slide)
