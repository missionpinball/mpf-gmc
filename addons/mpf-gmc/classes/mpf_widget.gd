@tool
class_name MPFWidget
extends MPFSceneBase

func initialize(key: String, settings: Dictionary, context: String, priority: int = 0, kwargs: Dictionary = {}) -> void:
   super(key, settings, context, priority, kwargs)
   # Widgets accept positions
   self.position.x = settings["x"]
   self.position.y = settings["y"]
