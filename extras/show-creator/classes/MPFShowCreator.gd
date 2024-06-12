extends Sprite2D
class_name MPFShowCreator

## The root node for creating light shows for MPF.

## Frames per second: the number of show steps to generate per second of animation.
@export var fps: int = 30
## An AnimationPlayer node containing the animations to render as shows.
@export var animation_player: AnimationPlayer
## The name of an animation show to render and save as YAML
@export var animation_name: String
## If checked, lights will not be added to each show stop if they don't change.
@export var strip_unchanged_lights: bool = true
## If checked, show steps will be excluded from the show if they don't contain changes.
@export var strip_empty_times: bool = true
## If checked, colors will be saved with an opacity channel.
@export var use_alpha: bool = false

var lights = []
var time = 0.0
var cum_time = 0.0
var spf: float
var file: FileAccess
var file_path: String


func _ready():
	ProjectSettings.set_setting("display/window/size/window_width_override", self.texture.get_width())
	ProjectSettings.set_setting("display/window/size/window_height_override", self.texture.get_height())
	set_process(false)
	if not animation_player or not animation_name:
		printerr("No animation player or name defined.")
		return
	if not animation_player.has_animation(animation_name):
		printerr("Animation player does not have an animation '%s'" % animation_name)
		return
	self.spf = 1.0 / self.fps
	self.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	self.file_path = "%s/%s.yaml" % [OS.get_user_data_dir(), animation_name]
	self.file = FileAccess.open(self.file_path, FileAccess.WRITE)
	self.file.store_line("#show_version=6")

	await RenderingServer.frame_post_draw
	self.snapshot(true)
	self.animation_player.play(animation_name)
	self.animation_player.animation_finished.connect(self.on_animation_finished)
	set_process(true)

func _process(delta):
	time += delta
	cum_time += delta
	if time < self.spf:
		return
	time = 0.0
	self.snapshot()

func register_light(light: MPFShowLight):
	self.lights.append(light)

func snapshot(is_initial=false):
	var tex := get_viewport().get_texture().get_image()
	var light_lines := []
	for l in lights:
		var c = l.get_color(tex, strip_unchanged_lights)
		if c != null:
			light_lines.append("    %s: \"%s\"" % [l.name, c.to_html(use_alpha)])
	if light_lines or not strip_empty_times:
		if is_initial:
			file.store_line("- time: 0.0")
		else:
			file.store_line("- time: %0.5f" % cum_time)
		file.store_line("  lights:")
		for line in light_lines:
			file.store_line(line)

func on_animation_finished(_animation_name):
	set_process(false)
	file.close()
	OS.shell_show_in_file_manager(self.file_path)
	get_tree().quit()
