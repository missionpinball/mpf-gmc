@tool
class_name MPFVideoPlayer extends VideoStreamPlayer

enum EndBehavior {
    ## No special behavior after the video ends
    NOTHING,
    ## Remove the parent MPFSlide (or MPFWidget) that holds this VideoPlayer
    REMOVE_SLIDE,
    ## Call a custom method on this node
    CUSTOM_METHOD,
    ## Call a custom method on the parent MPFSlide (or MPFWidget) that holds this VideoPlayer
    PARENT_METHOD
}

## The action to take after this video finishes playing.
@export var end_behavior: EndBehavior
## An event (or comma-separated list of events) to be posted to MPF when the video finishes.
@export var events_when_stopped: String
## The name of the method to call when the video finishes when end behavior is a method.
@export var end_method: String

func _ready() -> void:
    self.finished.connect(self._on_finished)

func _on_finished() -> void:
    if end_behavior == EndBehavior.REMOVE_SLIDE:
        self._remove_self()
    elif end_behavior == EndBehavior.CUSTOM_METHOD:
        self[end_method].call()
    elif end_behavior == EndBehavior.PARENT_METHOD:
        self._get_parent()[end_method].call()

    if events_when_stopped:
        # TBD: Will the events come as a string or an array?
        for e in events_when_stopped.split(","):
            MPF.server.send_event(e.strip_edges())

func _remove_self():
    var parent = self._get_parent()
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

func _get_parent():
    var parent = self
    while parent:
        if parent is MPFSlide or parent is MPFWidget:
            return parent
        parent = parent.get_parent()
    if not parent:
        printerr("No parent slide or widget found?")
        return

