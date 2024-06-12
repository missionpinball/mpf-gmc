extends Node2D
class_name MPFShowLight

var current_color

func _ready():
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
