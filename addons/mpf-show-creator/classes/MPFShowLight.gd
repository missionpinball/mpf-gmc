@tool
extends Sprite2D
class_name MPFShowLight

const PLAYFIELD_WIDTH_INCHES = 22.0
enum InsertShapes { CIRCLE }

@export var shape: InsertShapes = InsertShapes.CIRCLE:
	set(value):
		shape = value
		self.scale_to_inches()

var current_color

func _ready():
	self.scale_to_inches()
	if Engine.is_editor_hint():
		self.set_notify_transform(true)
		return
	var parent = self.get_parent()
	while parent:
		if parent is MPFShowCreator:
			parent.register_light(self)
		parent = parent.get_parent()

func restore(props):
	var global_space = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	# Legacy support
	if props is Vector2:
		self.global_position = props * global_space
		return
	if props.has("position"):
		self.global_position = props["position"] * global_space
	if props.has("scale"):
		self.scale = props["scale"]
	if props.has("rotation"):
		self.rotation = props["rotation"]
	if props.has("shape"):
		self.shape = props["shape"]
		self.scale_to_inches()

func get_color(data: Image, suppress_unchanged: bool = false):
	var color = data.get_pixelv(self.global_position)
	if color == current_color and suppress_unchanged:
		return null
	current_color = color
	return color

func _get_configuration_warnings():
	if self.global_position == Vector2(-1, -1):
	# if self.position.x == 0 and self.position.y == 0:
		return ["Light has not been positioned."]
	return []

func _notification(what):
	if(what == NOTIFICATION_TRANSFORM_CHANGED):
		self.update_configuration_warnings()

func scale_to_inches():
	var path: String
	var width: float
	match self.shape:
		InsertShapes.CIRCLE:
			path = "res://addons/mpf-show-creator/inserts/circle-insert.svg"
			width = 0.5
		_:
			push_error("No texture for selected shape.")
	# Lots of extra steps here because Godot warns against direct loading
	var base_texture = load(path)
	var image: Image = base_texture.get_image()
	var mapped_texture = ImageTexture.create_from_image(image)
	var playfield_ppi = ProjectSettings.get_setting("display/window/size/viewport_width") / PLAYFIELD_WIDTH_INCHES
	var image_size = mapped_texture.get_size()
	var image_aspect_ratio = image_size.x / image_size.y
	print("Light has dimensions %s x %s, aspect ratio %s" % [image_size.x, image_size.y, image_aspect_ratio])
	var scaled_size = Vector2(width * playfield_ppi, width * playfield_ppi * image_aspect_ratio)
	print(" - calculated a scaled size of %s" % scaled_size)
	mapped_texture.set_size_override(scaled_size)
	self.texture = mapped_texture
