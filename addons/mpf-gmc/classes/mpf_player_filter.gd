extends Node2D
class_name MPFPlayerFilter

## Shows or hides itself (and thus children) based on player counts.

## If set, this node will only render if the number of players is greater than or equal to this value.
@export var min_players: int
## If set, this node will only render if the number of players is less than or equal to this value.
@export var max_players: int
## If set, this node will only render if the current player is the set number.
@export var player_number: int = 0

var known_player_count: int

func _ready() -> void:
	self.known_player_count = MPF.game.num_players
	# Always listen for player count changes
	MPF.game.connect("player_added", self._update_known_players)
	self._update_visibility()

func _should_show() -> bool:
	if self.player_number > 0:
		var current_player_number = MPF.game.player.get("number")
		if not current_player_number:
			MPF.log.error("MPFPlayerFilter '%s' can only use the player_number setting during game modes.", self.name)
			return false # fast exit and hide when errored

		# always hide when mismatch
		if self.player_number != MPF.game.player.get('number'):
			return false

	if min_players > 0 and min_players > self.known_player_count:
		return false
	if max_players > 0 and self.known_player_count > max_players:
		return false
	return true

func _update_known_players(total_players: int) -> void:
	self.known_player_count = total_players
	self._update_visibility()

func _update_visibility() -> void:
	if self._should_show():
		self.show()
	else:
		self.hide()

