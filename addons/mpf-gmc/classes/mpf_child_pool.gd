@tool
class_name MPFChildPool
extends Node2D

enum PlaybackMethod {RANDOM, RANDOM_NO_REPEAT, RANDOM_FORCE_ALL, SEQUENTIAL}

@export var playback_method: PlaybackMethod
@export var track_per_player: bool
@export var reset_on_game_end: bool
@export var child_method: String
@export var call_child_method_in_editor: bool

var _tracker: Dictionary
var _player_num: int

func _ready() -> void:
    if self.visible:
        self._initialize()

func show() -> void:
    if self.visible:
        return
    if not self._tracker:
        self._initialize()
    self.visible = true

func _initialize():
    # Pure random does not require a tracker
    if self.playback_method != PlaybackMethod.RANDOM:
        self._player_num = MPF.game.player.number if self.track_per_player else 0
        self._tracker = MPF.game.get_tracker(self.get_path(), self._player_num, reset_on_game_end)

    var child_count = self.get_child_count()
    if not child_count:
        return

    var child_to_show = self._find_next_child() if child_count > 1 else self.get_child(0)
    for c in self.get_children():
        if c == child_to_show:
            c.show()
            if child_method and (call_child_method_in_editor or not Engine.is_editor_hint()):
                c[child_method].call()
        else:
            c.hide()

func _find_next_child():
    if self.playback_method == PlaybackMethod.RANDOM:
        return self.get_children().pick_random()
    if self.playback_method == PlaybackMethod.RANDOM_NO_REPEAT:
        return self._find_random_child()
    if self.playback_method == PlaybackMethod.RANDOM_FORCE_ALL:
        return self._find_random_child_force_all()
    if self.playback_method == PlaybackMethod.SEQUENTIAL:
        return self._find_sequential_child()

func _find_sequential_child() -> Node:
    var idx = self._tracker["last_index"] + 1
    if idx >= self.get_child_count():
        idx = 0
    self._tracker["last_index"] = idx
    return self.get_child(idx)

func _find_random_child() -> Node:
    var idx = self._tracker["last_index"]
    var r = self.get_child_count()
    var i = randi_range(0, r-1)
    while idx == i:
        i = randi_range(0, r-1)
    self._tracker["last_index"] = i
    return self.get_child(i)

func _find_random_child_force_all() -> Node:
    var used = self._tracker["used"]
    var r = self.get_child_count()
    var i = randi_range(0, r-1)
    while used.find(i) != -1:
        i = randi_range(0, r-1)
    # If this is the last unused one, clear the array
    if used.size() == r-1:
        used.empty()
    # But add this one after clearing, to avoid back-to-back
    used.append(i)
    return self.get_child(i)
