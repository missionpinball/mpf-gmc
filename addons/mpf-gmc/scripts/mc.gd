# Base singleton for managing all MC-related references,
# including windows, displays, slides, and widgets
@tool
extends Node

var window: Node
var slides := {}
var widgets := {}

func _init() -> void:
    self.traverse_tree_for("slides", slides)
    self.traverse_tree_for("widgets", widgets)

    MPF.log.info("Generated slide lookups: %s", slides)

func register_window(inst: Node) -> void:
    window = inst

func play(payload: Dictionary) -> void:
    var command = payload.name
    match command:
        "slides_play":
            self.window.play_slides(payload)

func get_slide(slide_name: String, preload_only: bool = false) -> MPFSlide:
    assert(slide_name in slides, "Unknown slide name '%s'" % slide_name)
    # If this is the first access, load the scene
    if slides[slide_name] is String:
        slides[slide_name] = load(slides[slide_name])
    if preload_only:
        return
    return slides[slide_name].instantiate()

func traverse_tree_for(obj_type: String, acc: Dictionary) -> void:
    # Start by traversing the root folder for this object type
    self.recurse_dir("res://%s" % obj_type, acc)
    # Then traverse the mode folders for subfolders of this object type
    var dir = DirAccess.open("res://modes")
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while (file_name != ""):
        if file_name == obj_type and dir.current_is_dir():
            self.recurse_dir("%s/%s" % [dir, file_name], acc)
        file_name = dir.get_next()
    # Then look for defaults included with GMC
    var defaults = {}
    self.recurse_dir("res://addons/mpf-gmc/%s" % obj_type, defaults)
    # And map over to fill in defaults for any missing scenes
    for d in defaults:
        if d not in acc:
            acc[d] = defaults[d]

func recurse_dir(path, acc, ext="tscn") -> void:
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while (file_name != ""):
            if file_name.ends_with(".%s" % ext):
                acc[file_name.split(".")[0]] = "%s/%s" % [path, file_name]
            file_name = dir.get_next()
    #else:
    #    print("An error occurred when trying to access the path '%s'." % dir)
