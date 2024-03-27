# Base singleton for managing all MC-related references,
# including windows, displays, slides, and widgets

extends Node

var window: Node
var displays := {}
var slides := {}
var widgets := {}

func _init() -> void:
    print("Initializng MC")
    self.traverse_tree_for("slides", slides)
    self.traverse_tree_for("widgets", widgets)

    MPF.log.info("Generated slide lookups: %s", slides)

func play_slides(payload: Dictionary) -> void:
    MPF.log.info("Playing slide with payload %s", payload)
    for slide_name in payload.settings.keys():
        if slide_name in slides:
            ## TODO: add a slide stack
            pass

func register_window(inst: Node) -> void:
    window = inst
    # Identify the children of the window of type MPFDisplay
    for c in inst.get_children():
        # TODO: create a type for display
        displays[c.name] = c

func traverse_tree_for(obj_type: String, acc: Dictionary) -> void:
    # Start by traversing the root folder for this object type
    self.recurse_dir("res://%s" % obj_type, acc)
    # Then traverse the mode folders for subfolders of this object type
    var dir = DirAccess.open("res://modes")
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while (file_name != ""):
        if file_name == obj_type and dir.current_is_dir():
            print("Found directory: " + file_name + " in mode " + dir)
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
    print("Recursing dir at path %s" % path)
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while (file_name != ""):
            if dir.current_is_dir():
                print("Found directory: " + file_name)
            else:
                print("Found file: " + file_name)
            if file_name.ends_with(".%s" % ext):
                acc[file_name.split(".")[0]] = file_name
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path '%s'." % dir)
