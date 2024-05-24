extends ColorRect

@export var dot_columns: int = 64 : set = _set_columns
@export var hardness: float = 2.0 : set = _set_hardness

# Called when the node enters the scene tree for the first time.
func _ready():
	self.material.set_shader_parameter("dot_columns", self.dot_columns)
	self.material.set_shader_parameter("display_width", self.size.x)
	self.material.set_shader_parameter("display_height", self.size.y)
	self.material.set_shader_parameter("hardness", self.hardness)
	self.material.set_shader_parameter("color", self.color)

func _set_columns(value):
	dot_columns = value
	self.material.set_shader_parameter("dot_columns", value)

func _set_hardness(value):
	hardness = value
	self.material.set_shader_parameter("hardness", value)
