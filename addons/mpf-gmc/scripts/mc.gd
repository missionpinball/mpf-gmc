# Base singleton for managing all MC-related references,
# including windows, displays, slides, and widgets
@tool
extends Node

var sound: Node
var window: Node
var slides := {}
var widgets := {}
var sounds := {}

func _init() -> void:
    self.traverse_tree_for("slides", slides)
    self.traverse_tree_for("widgets", widgets)
    for ext in ["tres", "wav", "ogg"]:
        self.traverse_tree_for("sounds", sounds, ext)

    MPF.log.info("Generated slide lookups: %s", slides)
    MPF.log.info("Generated widget lookups: %s", widgets)
    MPF.log.info("Generated sound lookups: %s", sounds)

func _enter_tree():
    print("MC entering the tree")
    sound = preload("sound_player.gd").new()

    # Process is only called on children in the tree, so add the children
    # that need to call process
    self.add_child(sound)

func register_window(inst: Node) -> void:
    window = inst

func play(payload: Dictionary) -> void:
    var command = payload.name
    match command:
        "slides_play":
            self.window.play_slides(payload)
        "widgets_play":
            self.window.play_widgets(payload)
        "sounds_play":
            self.sound.play_sounds(payload)

func get_slide_instance(slide_name: String, preload_only: bool = false) -> MPFSlide:
    assert(slide_name in slides, "Unknown slide name '%s'" % slide_name)
    return self._get_scene(slide_name, self.slides, preload_only) as MPFSlide

func get_widget_instance(widget_name: String, preload_only: bool = false) -> MPFWidget:
    assert(widget_name in widgets, "Unknown widget name '%s'" % widget_name)
    return self._get_scene(widget_name, self.widgets, preload_only) as MPFWidget

func get_sound_instance(sound_name: String, preload_only: bool = false):
    assert(sound_name in sounds, "Unknown sound name '%s'" % sound_name)
    return self._get_scene(sound_name, self.sounds, preload_only)

func _get_scene(name: String, collection: Dictionary, preload_only: bool = false):
    # If this is the first access, load the scene
    if collection[name] is String:
        collection[name] = load(collection[name])
    if preload_only:
        return
    if collection == self.sounds:
        return collection[name]
    return collection[name].instantiate()

func traverse_tree_for(obj_type: String, acc: Dictionary, ext="tscn") -> void:
    # Start by traversing the root folder for this object type
    self.recurse_dir("res://%s" % obj_type, acc, ext)
    self.recurse_modes(obj_type, acc, ext)
    # Then look for defaults included with GMC
    var defaults = {}
    self.recurse_dir("res://addons/mpf-gmc/%s" % obj_type, defaults, ext)
    # And map over to fill in defaults for any missing scenes
    for d in defaults:
        if d not in acc:
            acc[d] = defaults[d]

func recurse_dir(path, acc, ext="tscn") -> void:
    var dir = DirAccess.open(path)
    # If this path does not exist, that's okay
    if not dir:
        return
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while (file_name != ""):
            if dir.current_is_dir():
                self.recurse_dir("%s/%s" % [path, file_name], acc, ext)
            elif file_name.ends_with(".%s" % ext):
                acc[file_name.split(".")[0]] = "%s/%s" % [path, file_name]
            file_name = dir.get_next()

func recurse_modes(obj_type: String, acc: Dictionary, ext="tscn") -> void:
    # Traverse the mode folders for subfolders of this object type
    var dir = DirAccess.open("res://modes")
    # If this is a new project there may not be modes
    if not dir:
        return
    dir.list_dir_begin()
    var mode = dir.get_next()
    while (mode != ""):
        var mdir = DirAccess.open("res://modes/%s" % mode)
        mdir.list_dir_begin()
        var file_name = mdir.get_next()
        while (file_name != ""):
            if file_name == obj_type and mdir.current_is_dir():
                self.recurse_dir("res://modes/%s/%s" % [mode, obj_type], acc, ext)
            file_name = mdir.get_next()
        mode = dir.get_next()
