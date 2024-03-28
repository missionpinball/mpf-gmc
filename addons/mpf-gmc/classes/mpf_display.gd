@tool
class_name MPFDisplay extends Node2D


@export var is_default: bool = false
@export var initial_slide: PackedScene
var _slide_stack = []

# SAMPLE SLIDES_PLAY PAYLOAD:
#{
    # "name": "slides_play",
    # "settings": {
    #     "attract": {
    #         "target": <null>,
    #         "background_color": [0, 0, 0, 1],
    #         "priority": <null>,
    #         "show": true,
    #         "force": false,
    #         "expire": <null>,
    #         "slide": <null>,
    #         "tokens": {  },
    #         "action": "play"
    #     }
    #},
    # "context": "attract",
    # "calling_context": "mode_attract_started",
    # "priority": 10,
    # "cmd": "slides_play"
#}

func _ready() -> void:
    if not self.initial_slide:
        return
    self.add_child(self.initial_slide.instantiate())
    MPF.server.connect("clear", self._on_clear)


func process_slide(slide_name: String, action: String, settings: Dictionary, context: String, priority: int = 0) -> void:
    # See if this slide already exists
    var slide: MPFSlide
    for s in _slide_stack:
        if s.name == slide_name:
            slide = s
    match action:
        "play":
            # Don't play a slide that's already there
            if not slide:
                self.play_slide(slide_name, settings, context, priority)
        "remove":
            if slide:
                self.remove_slide(slide)

func play_slide(slide_name: String, settings: Dictionary, context: String, priority: int = 0) -> void:
    var slide = MPF.mc.get_slide(slide_name)
    slide.priority = settings['priority'] + priority if settings['priority'] else priority
    slide.context = context
    self._slide_stack.append(slide)
    self.add_child(slide)
    self._update_stack()

func remove_slide(slide) -> void:
    self._slide_stack.erase(slide)
    self._update_stack()

func _update_stack() -> void:
    # Sort the stack by priority
    self._slide_stack.sort_custom(
        func(a: Node, b: Node): return a.priority < b.priority
    )
    # Update the children
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
