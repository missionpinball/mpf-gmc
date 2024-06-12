@tool
extends Node2D
class_name MPFShowLight

var current_color

func _ready():
	if Engine.is_editor_hint():
		return
	var parent = self.get_parent()
	while parent:
		if parent is MPFShowCreator:
			parent.register_light(self)
		parent = parent.get_parent()

func get_color(data: Image, suppress_unchanged: bool = false):
	var color = data.get_pixelv(self.position)
	if color == current_color and suppress_unchanged:
		return null
	current_color = color
	return color

func _get_configuration_warnings():
	if self.position == Vector2(-1, -1):
	# if self.position.x == 0 and self.position.y == 0:
		return ["Light has not been positioned."]
	return []
