@tool
class_name MPFWidget
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

    self._variables = MPF.util.find_variables(self)
    self.update(settings, kwargs)

func update(settings: Dictionary, kwargs: Dictionary = {}) -> void:
    for c in self._variables:
        c.update(settings, kwargs)
