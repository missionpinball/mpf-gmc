class_name MPFDMDDisplay
extends MPFDisplay

enum PixelOrder {
	RGB,
	RBG,
	GRB
}

enum GPUStrategy {
	PRODUCTION,
	ALWAYS,
	NEVER
}

@export var resolution: Vector2i
@export var pixel_order: PixelOrder = PixelOrder.RGB
@export var use_gpu: GPUStrategy = GPUStrategy.NEVER

var _rgb_shift_fn: Callable

func _ready() -> void:
	super()
	if not resolution:
		var dims = self.get_viewport_rect()
		resolution = Vector2i(dims.size.x, dims.size.y)
	RenderingServer.frame_pre_draw.connect(self._pre_draw)
	# Force additional output to continue rendering even if
	# the window is not visible. Requires Godot 4.3
	if Engine.get_version_info().hex >= 0x040300:
		DisplayServer.register_additional_output(self)

	if use_gpu == GPUStrategy.ALWAYS or (use_gpu == GPUStrategy.PRODUCTION and OS.has_feature("template")):
		self.log.warning("GPU-based DMD shading is in progress, please inquire!")
	# Until GPU is automated, always use software
	if pixel_order == PixelOrder.RBG:
		_rgb_shift_fn = self._shift_rbg
	elif pixel_order == PixelOrder.GRB:
		_rgb_shift_fn = self._shift_grb

func _exit_tree() -> void:
	if Engine.get_version_info().hex >= 0x040300:
		DisplayServer.unregister_additional_output(self)

func _pre_draw():
	# If the drawing changes, wait for the new draw and capture
	if RenderingServer.has_changed():
		await RenderingServer.frame_post_draw
		self._capture()

func _capture() -> void:
	# Ignore draw updates if no BCP is connected
	if not MPF.server._client:
		return
	var tex := get_viewport().get_texture().get_image()
	# Downsize the image to the size of the DMD, no interpolation
	tex.resize(resolution.x, resolution.y, 0)
	# If RGB shifting is needed, do it now
	self._rgb_shift_fn and self._rgb_shift_fn.call(tex)
	var data = tex.get_data()
	# Send the data bytes from the frame to MPF for DMD handling
	MPF.server.send_bytes("rgb_dmd_frame", data, {"name": name})

func _apply_shader() -> void:
	# Not yet implemented. Well it works, but not automatic
	pass

func _shift_grb(tex: Image) -> void:
	for y in range(resolution.y):
		for x in range(resolution.x):
			var color = tex.get_pixel(x, y)
			tex.set_pixel(x, y, Color(color.g, color.r, color.b, color.a))

func _shift_rbg(tex: Image) -> void:
	for y in range(resolution.y):
		for x in range(resolution.x):
			var color = tex.get_pixel(x, y)
			tex.set_pixel(x, y, Color(color.r, color.b, color.g, color.a))
