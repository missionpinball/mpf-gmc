@tool
class_name MPFVariable extends Label

@export_enum("Current Player", "Machine", "Player 1", "Player 2", "Player 3", "Player 4") var variable_type: String = "Current Player"
@export var variable_name: String
@export var comma_separate: bool
@export var min_digits: int = -1

var format_template: String = "%s"

func _ready() -> void:
    if min_digits > 0:
      format_template = ("%"+str(min_digits)+"d")
    if variable_type == "Machine":
        self._set_text(MPF.game.machine_vars[self.variable_name])
        # TODO: Dynamically update machine vars?
    else:
        var player_num = int(variable_type.right(1))
        var is_current_player = variable_type == "Current Player" or player_num == MPF.game.player['number']
        if is_current_player:
            MPF.game.connect("player_update", self._on_player_update)
            self._set_text(MPF.game.player[self.variable_name])
        else:
            self._set_text(MPF.game.players[player_num - 1][self.variable_name])

func _set_text(value):
    if value is String:
      self.text = value
    elif comma_separate and value >= 1000:
      self.text = MPF.game.comma_sep(value)
    else:
      self.text = format_template % value

func _on_player_update(var_name, value):
    if var_name == variable_name:
        self._set_text(value)
