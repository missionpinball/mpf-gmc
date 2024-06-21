class_name MPFWidget
extends MPFSceneBase

## A scene root for reusable Widgets that can be added to and removed from slides using events and the widget_player.

func initialize(n: String, settings: Dictionary, c: String, p: int = 0, kwargs: Dictionary = {}) -> void:
	super(n, settings, c, p, kwargs)
	# Widgets accept positions
	self.position.x = settings["x"]
	self.position.y = settings["y"]
