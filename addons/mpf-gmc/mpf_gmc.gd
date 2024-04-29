@tool
extends Node

var game
var log
var media
var player
var server
var util
var keyboard: = {}
var config



func _enter_tree():

    self.config = ConfigFile.new()
    var err = self.config.load("res://gmc.cfg")
    if err != OK:
        printerr("Error loading config file: %s" % err)
    # print("resource path is %s" % self.resource_path)
    # Any default script can be overridden with a custom one
    # This is done explicitly line-by-line for optimized preload and relative paths

    for s in [
            # Static utility functions first
            ["util", preload("scripts/utilities.gd")],
            # Log is needed for the rest
            ["log", preload("scripts/log.gd")],
            # Game should be loaded next
            ["game", preload("scripts/mpf_game.gd")],
            # Server depends on Game, should be loaded after
            ["server", preload("scripts/bcp_server.gd")],
            # Media controller can come last
            ["media", preload("scripts/media.gd")]
    ]:
        var script = self.config.get_value("gmc", "%s_script" % s[0], false)
        if script:
            self[s[0]] = load(script).new()
        else:
            self[s[0]] = s[1].new()

    # Process is only called on children in the tree, so add the children
    # that need to call process or that have enter_tree methods
    self.add_child(server)
    self.add_child(media)

func _ready():
    if self.config:
        if self.config.has_section("keyboard"):
            for key in self.config.get_section_keys("keyboard"):
                keyboard[key.to_upper()] = self.config.get_value("keyboard", key)
        self.media.sound.initialize(self.config)

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
        # get_tree().quit()
        return

    if keycode in keyboard:
        var cfg = keyboard[keycode]
        match cfg[0]:
            "event":
                # Only handle events on the press, not the release
                if not event.is_pressed():
                    return
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
