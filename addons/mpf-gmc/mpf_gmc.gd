extends Node

var server
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
    server = preload("scripts/bcp_server.gd").new()
    # MC can come last?
    mc = preload("scripts/mc.gd").new()

    # Process is only called on children in the tree, so add the children
    # that need to call process
    self.add_child(server)
