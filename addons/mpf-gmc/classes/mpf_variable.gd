@tool
class_name MPFVariable extends Label

@export_enum("Current Player", "Machine", "Event Arg", "Player 1", "Player 2", "Player 3", "Player 4") var variable_type: String = "Current Player"
@export var variable_name: String
@export var comma_separate: bool
@export var min_digits: int = -1
@export var template: String = ""
@export var initialize_empty: bool = true
@export var update_event: String = ""

var var_template: String = "%s"

func _ready() -> void:
    if min_digits > 0:
      var_template = ("%0"+str(min_digits)+"d")
    if variable_type == "Machine":
        self.update_text(MPF.game.machine_vars.get(self.variable_name))
        # TODO: Dynamically update machine vars?
    elif variable_type == "Event Arg":
        if initialize_empty:
            self.text = ""
    else:
        var player_num = int(variable_type.right(1))
        var is_current_player = variable_type == "Current Player" or player_num == MPF.game.player.get('number')
        if is_current_player:
            MPF.game.connect("player_update", self._on_player_update)
            self.update_text(MPF.game.player.get(self.variable_name))
        elif MPF.game.players.size() >= player_num:
            self.update_text(MPF.game.players[player_num - 1].get(self.variable_name))

    if self.update_event:
        MPF.server.add_event_handler(self.update_event, self.update)

func _exit_tree() -> void:
    if self.update_event:
        MPF.server.remove_event_handler(self.update_event, self.update)

func update(settings: Dictionary, kwargs: Dictionary = {}) -> void:
    if variable_type != "Event Arg":
        return
    if variable_name in settings:
        self.update_text(settings[variable_name])
    # The value may be passed via the tokens: config
    elif variable_name in settings.get("tokens", {}):
        self.update_text(settings.tokens[variable_name])
    # Or the value may be part of the triggering event
    elif variable_name in kwargs:
        self.update_text(kwargs[variable_name])

func update_text(value):
    if value == null:
        self.text = ""
        return
    if value is int or value is float:
        if comma_separate and value >= 1000:
            value = MPF.util.comma_sep(value)
        else:
            value = var_template % value
    if template:
        self.text = template % value
    else:
        self.text = value

func _on_player_update(var_name, value):
    if var_name == variable_name:
        self.update_text(value)
