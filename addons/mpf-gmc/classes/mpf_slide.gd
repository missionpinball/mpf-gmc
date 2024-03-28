@tool
class_name MPFSlide
extends Node2D

var priority: int = 0
var context: String
var key: String

func initialize(key: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
    # The "name" is the name of the root node, which could be
    # anything or case-sensitive. Set an explicit key instead.
    self.key = key
    self.priority = settings['priority'] + priority if settings['priority'] else priority
    self.context = context

    self.update(settings, kwargs)

func update(settings: Dictionary, kwargs: Dictionary = {}) -> void:
    # TODO: Recurse through all sub-children
    for c in self.get_children():
        if c is MPFVariable:
            c.update(settings, kwargs)
