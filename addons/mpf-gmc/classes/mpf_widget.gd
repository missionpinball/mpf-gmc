@tool
class_name MPFWidget
extends MPFSceneBase

func initialize(n: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	super(n, settings, c, p, kwargs)
	# Widgets accept positions
	self.position.x = settings["x"]
	self.position.y = settings["y"]
