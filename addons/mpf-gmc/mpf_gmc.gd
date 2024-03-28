@tool
extends Node

var server
var game
var log
var mc
var player
var keyboard: = {}

func _enter_tree():
    # Log is top-most
    log = preload("scripts/log.gd").new()
    # Game should be loaded first
    game = preload("scripts/mpf_game.gd").new()
    # Server depends on Game, should be loaded after
    server = preload("scripts/bcp_server.gd").new()
    # MC can come last?
    mc = preload("scripts/mc.gd").new()
    print("GMC is ready")

    # Process is only called on children in the tree, so add the children
    # that need to call process
    self.add_child(server)

    var config = ConfigFile.new()
    var err = config.load("res://gmc.cfg")
    if err == OK:
        if config.has_section("keyboard"):
            print("Making some keymaps!")
            for key in config.get_section_keys("keyboard"):
                keyboard[key.to_upper()] = config.get_value("keyboard", key)

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_class("InputEventKey"):
        return
    # Don't support holding down a key
    if event.is_echo():
        return
    var keycode = OS.get_keycode_string(event.get_key_label_with_modifiers()).to_upper()
    #print(keycode)
    if keycode == "ESCAPE":
        # Cannot use quit() method because it won't cleanly shut down threads
        # Instead, send a notification to the main thread to shut down
        #get_tree().notification(NOTIFICATION_WM_CLOSE_REQUEST)
        get_tree().quit()
        return

    if keycode in keyboard:
        var cfg = keyboard[keycode]
        match cfg[0]:
            "event":
                MPF.server.send_event(cfg[1])
            "switch":
                var action
                var state
                if cfg.size() < 3:
                    action = "active" if event.is_pressed() else "inactive"
                elif not event.is_pressed():
                    return
                else:
                    action = cfg[2]
                match action:
                    "active":
                        state = 1
                    "inactive":
                        state = 0
                    "toggle":
                        state = -1
                MPF.server.send_switch(cfg[1], state)
            _:
                return
        get_tree().get_root().set_input_as_handled()
