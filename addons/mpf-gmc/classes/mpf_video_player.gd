@tool
class_name MPFVideoPlayer extends VideoStreamPlayer

enum EndBehavior {NOTHING, REMOVE_SLIDE, POST_EVENT}

@export var end_behavior: EndBehavior
@export var events_when_stopped: String

func _ready() -> void:
    self.finished.connect(self._on_finished)

func _on_finished() -> void:
    match end_behavior:
        EndBehavior.REMOVE_SLIDE:
            self._remove_self()
        EndBehavior.POST_EVENT:
            MPF.server.send_event("video_finished")
    if events_when_stopped:
        for e in events_when_stopped.split(","):
            MPF.server.send_event(e.strip_edges())

func _remove_self():
    var parent = self
    while parent:
        if parent is MPFSlide or parent is MPFWidget:
            break
        parent = parent.get_parent()
    if not parent:
        printerr("No parent siled or widget found?")
        return
    var grandparent = parent.get_parent()
    while grandparent:
        if parent is MPFSlide and grandparent is MPFDisplay:
            break
        elif parent is MPFWidget and grandparent is MPFSlide:
            break
        grandparent = grandparent.get_parent()
    if not grandparent:
        return
    grandparent.action_remove(parent)
