class_name MPFChildPool
extends Control
## Chooses one child to display when entering the scene tree.

enum PlaybackMethod {
	## A child will be chosen at random. Repetition is allowed.
	RANDOM,
	## A child will be chosen at random, but never the same twice in a row.
	RANDOM_NO_REPEAT,
	## A child will be chosen at random, and all will be chosen before any repeats.
	RANDOM_FORCE_ALL,
	## The first child will be chosen first, then the second, et cetera.
	SEQUENTIAL
}


@export var playback_method: PlaybackMethod
## If checked, randomness/sequences will be unique for each player.
@export var track_per_player: bool
## If checked, randomness/sequences will reset for each game.
@export var reset_on_game_end: bool
## If checked, the next child will be selected each time the pool becomes visible
@export var advance_on_show: bool = false
## If checked, the next child will be shown on a repeat event even if one is already showing
@export var advance_when_showing: bool = false
## The name of a method to call when selecting a child to display.
@export var child_method: String
## If checked, the child_method will be called when the scene is opened in the Editor.
@export var call_child_method_in_editor: bool

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger
var _tracker: Dictionary
var _player_num: int

func _enter_tree() -> void:
	self.log = preload("res://addons/mpf-gmc/scripts/log.gd").new("ChildPool<%s>" % self.name)
	for c in self.get_children():
		c.hide()

func _ready() -> void:
	if self.visible:
		self._initialize()

@warning_ignore("native_method_override")
func show() -> void:
	if self.visible and not self.advance_when_showing:
		return
	if self.advance_on_show or self.advance_when_showing or not self._tracker:
		self._initialize()
	self.visible = true

func _initialize() -> void:
	# Pure random does not require a tracker
	if self.playback_method != PlaybackMethod.RANDOM:
		self._player_num = MPF.game.player.number if self.track_per_player else 0
		self._tracker = MPF.game.get_tracker(self.get_path(), self._player_num, reset_on_game_end)

	var child_count: int = self.get_child_count()
	if not child_count:
		self.log.info("No children found, will not display anything.")
		return

	var child_to_show: Node = self._find_next_child() if child_count > 1 else self.get_child(0)
	self.log.info("Selected child %s to show.", child_to_show.name)
	for c in self.get_children():
		if c == child_to_show:
			c.show()
			if child_method and (call_child_method_in_editor or not Engine.is_editor_hint()):
				c[child_method].call()
		else:
			c.hide()

func _find_next_child() -> Node:
	if self.playback_method == PlaybackMethod.RANDOM:
		return self.get_children().pick_random()
	if self.playback_method == PlaybackMethod.RANDOM_NO_REPEAT:
		return self._find_random_child()
	if self.playback_method == PlaybackMethod.RANDOM_FORCE_ALL:
		return self._find_random_child_force_all()
	if self.playback_method == PlaybackMethod.SEQUENTIAL:
		return self._find_sequential_child()
	return null

func _find_sequential_child() -> Node:
	var idx: int = self._tracker["last_index"] + 1
	if idx >= self.get_child_count():
		idx = 0
	self._tracker["last_index"] = idx
	return self.get_child(idx)

func _find_random_child() -> Node:
	var idx: int = self._tracker["last_index"]
	var r: int = self.get_child_count()
	var i: int = randi_range(0, r-1)
	while idx == i:
		i = randi_range(0, r-1)
	self._tracker["last_index"] = i
	return self.get_child(i)

func _find_random_child_force_all() -> Node:
	var used: Array = self._tracker["used"]
	var r: int = self.get_child_count()
	var i: int = randi_range(0, r-1)
	while used.find(i) != -1:
		i = randi_range(0, r-1)
	# If this is the last unused one, clear the array
	if used.size() == r-1:
		used.clear()
	# But add this one after clearing, to avoid back-to-back
	used.append(i)
	return self.get_child(i)
