@tool
extends Node

var server
var game
var log
var mc
var player

func _ready() -> void:
    # Log is top-most
    log = preload("scripts/log.gd").new()
    # Game should be loaded first
    game = preload("scripts/mpf_game.gd").new()
    # Server depends on Game, should be loaded after
    server = preload("scripts/bcp_server.gd").new()
    # MC can come last?
    mc = preload("scripts/mc.gd").new()
    print("GMC is ready")

func _enter_tree():
    print("GMC entering tree")
    # Process is only called on children in the tree, so add the children
    # that need to call process
    self.add_child(server)


    # add_custom_type("MPFWindow", "Node2D", preload("classes/mpf_window.gd"), null)
    # add_custom_type("MPFDisplay", "Node2D", preload("classes/mpf_display.gd"), null)
    # add_custom_type("MPFSlide", "Node2D", preload("classes/mpf_slide.gd"), null)
    # add_custom_type("MPFDisplay", "Node2D", preload("classes/mpf_display.gd"), null)
