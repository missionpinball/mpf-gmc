extends Node

var events
var game
var log
var mc
var player

func _enter_tree() -> void:
    # Log is top-most
    log = preload("scripts/log.gd").new()
    # Game should be loaded first
    game = preload("scripts/mpf_game.gd").new()
    # Server depends on Game, should be loaded after
    events = preload("scripts/bcp_server.gd").new()
    # MC can come last?
    mc = preload("scripts/mc.gd").new()

    events.listen()
