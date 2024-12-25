class_name MPFDMDDisplay
extends MPFDisplay

@export var resolution: Vector2i

func _ready() -> void:
	super()
	if not resolution:
		var dims = self.get_viewport_rect()
		resolution = Vector2i(dims.size.x, dims.size.y)
	RenderingServer.frame_pre_draw.connect(self._pre_draw)
	# Force additional output to continue rendering even if
	# the window is not visible. Requires Godot 4.3
	DisplayServer.register_additional_output(self)

func _exit_tree() -> void:
	DisplayServer.unregister_additional_output(self)

func _pre_draw():
	if RenderingServer.has_changed():
		print(" - draw is changed?")
		await RenderingServer.frame_post_draw
		self._capture()
		print(" - draw is done?")


func _capture() -> void:
	var tex := get_viewport().get_texture().get_image()
	tex.crop(resolution.x, resolution.y)
	var color = tex.get_pixelv(Vector2i(0, 0))
	var data = tex.get_data()
	if not MPF.server._client:
		print("no client")
		return
	# MPF.server.send_event_with_args("rgb_dmd_frame", {"rawbytes": data, "name": self.name})
	MPF.server._send("rgb_dmd_frame?name=%s&bytes=%d" % [name, data.size()])
	MPF.server._client.put_data(data)
	# MPF.server._client.put_data("\n".to_ascii_buffer())
