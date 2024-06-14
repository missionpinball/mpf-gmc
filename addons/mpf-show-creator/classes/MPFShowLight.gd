@tool
extends Sprite2D
class_name MPFShowLight

const PLAYFIELD_WIDTH_INCHES = 20.25
const INSERT_DPI = 150
enum InsertShapes {
	## A basic circle
	CIRCLE,
	## A square with rounded corners
	SQUARE,
	## An elongated (2:1) triangle
	LONG_TRIANGLE,
	## Attach your own Texture of choice
	CUSTOM }

## The shape of the insert, for visual fidelity. Has no impact on the rendered show.
@export var shape: InsertShapes = InsertShapes.CIRCLE:
	set(value):
		shape = value
		self.scale_to_inches()
## The width (in inches) of the insert's smallest dimension. Will scale inserts based on a
## standard 20.25" playfield width. Has no effect on CUSTOM shapes.
@export var width_inches: float = 0.5:
	set(value):
		width_inches = value
		self.scale_to_inches()
@export var tags: Array

var current_color

func _ready():
	self.scale_to_inches()
	var parent = self.get_parent()
	while parent:
		if parent is MPFShowCreator:
			parent.register_light(self)
		parent = parent.get_parent()
	if Engine.is_editor_hint():
		self.set_notify_transform(true)
	# If not in editor, make it invisible
	else:
		self.visible = false

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
	if props.has("rotation_degrees"):
		self.rotation_degrees = props["rotation_degrees"]
	if props.has("shape"):
		self.shape = props["shape"]
		self.scale_to_inches()

func set_color(color: Color):
	self.modulate = color

func get_color(data: Image, suppress_unchanged: bool = false):
	var color = data.get_pixelv(self.global_position)
	if color == current_color and suppress_unchanged:
		return null
	current_color = color
	return color

func _get_configuration_warnings():
	if self.global_position == Vector2(-1, -1):
		return ["Light has not been positioned."]
	return []

func _notification(what):
	if(what == NOTIFICATION_TRANSFORM_CHANGED):
		self.update_configuration_warnings()

func scale_to_inches():
	var path: String
	match self.shape:
		InsertShapes.CIRCLE:
			path = "res://addons/mpf-show-creator/inserts/circle-insert.svg"
		InsertShapes.SQUARE:
			path = "res://addons/mpf-show-creator/inserts/square-insert.svg"
		InsertShapes.LONG_TRIANGLE:
			path = "res://addons/mpf-show-creator/inserts/long-triangle-insert.svg"
		InsertShapes.CUSTOM:
			return
		_:
			push_error("No texture for selected shape.")
	self.texture = load(path)
	var image: Image = self.texture.get_image()
	var mapped_texture = ImageTexture.create_from_image(image)
	var playfield_dpi = ProjectSettings.get_setting("display/window/size/viewport_width") / PLAYFIELD_WIDTH_INCHES

	# Find out how wide the image is naturally
	var image_width_inches = mapped_texture.get_width() / INSERT_DPI
	# Scale the image from natural width to desired width
	var image_width_scale = self.width_inches / image_width_inches
	# Scale the image from INSERT_DPI to PF_DPI so it's relatively to-scale
	var image_dpi_scale = playfield_dpi / INSERT_DPI
	# Combine the two scale levels
	var scale_factor = image_width_scale * image_dpi_scale
	self.scale = Vector2(scale_factor, scale_factor)
	# print("Scaling to %s because texture is %s px wide at %s DPI (aka %s inches) and playfield ppi is %s" %
	# 	[scale_factor, mapped_texture.get_width(), INSERT_DPI, image_width_inches, playfield_dpi])
	# print(" - that means scale by %s to convert image from %sin to %sin, and scale by %s to convert from %s DPI to %s DPI" %
	# 	[image_width_scale, image_width_inches, self.width_inches, image_dpi_scale, INSERT_DPI, playfield_dpi]
	# )
