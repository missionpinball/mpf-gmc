extends Node

var events
var game
var log
var player

func _enter_tree() -> void:
    # Log is top-most
    log = preload("log.gd").new()
    # Game should be loaded first
    game = preload("mpf_game.gd").new()
    # Server depends on Game, should be loaded after
    events = preload("bcp_server.gd").new()

    events.listen()
