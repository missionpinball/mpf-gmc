@tool
class_name MPFVariable extends Label

@export_enum("Current Player", "Machine", "Player 1", "Player 2", "Player 3", "Player 4") var variable_type: String = "Current Player"
@export var variable_name: String
@export var comma_separate: bool
@export var min_digits: int = -1
@export var template: String = ""

var var_template: String = "%s"

func _ready() -> void:
    if min_digits > 0:
      var_template = ("%0"+str(min_digits)+"d")
    if variable_type == "Machine":
        self._set_text(MPF.game.machine_vars.get(self.variable_name))
        # TODO: Dynamically update machine vars?
    else:
        var player_num = int(variable_type.right(1))
        var is_current_player = variable_type == "Current Player" or player_num == MPF.game.player.get('number')
        if is_current_player:
            MPF.game.connect("player_update", self._on_player_update)
            self._set_text(MPF.game.player.get(self.variable_name))
        elif MPF.game.players.size() >= player_num:
            self._set_text(MPF.game.players[player_num - 1].get(self.variable_name))

func _set_text(value):
    if not value:
        self.text = ""
    if value is int:
        if comma_separate and value >= 1000:
            value = MPF.game.comma_sep(value)
        else:
            value = var_template % value
    if template:
        self.text = template % value
    else:
        self.text = value

func _on_player_update(var_name, value):
    if var_name == variable_name:
        self._set_text(value)
