extends Sprite2D
class_name MPFShowCreator

## The root node for creating light shows for MPF.


const CONFIG_PATH = "user://mpf_show_creator.cfg"

## Frames per second: the number of show steps to generate per second of animation.
@export var fps: int = 30
## An AnimationPlayer node containing the animations to render as shows.
@export var animation_player: AnimationPlayer
## If checked, lights will not be added to each show stop if they don't change.
@export var strip_unchanged_lights: bool = true
## If checked, show steps will be excluded from the show if they don't contain changes.
@export var strip_empty_times: bool = true
## If checked, colors will be saved with an opacity channel.
@export var use_alpha: bool = false
## A list of group names (comma-separated) whose lights will be included
@export var light_groups: String = ""

var lights = []
var time = 0.0
var cum_time = 0.0
var spf: float
var file: FileAccess
var file_path: String
var _groups: Array
var animation_name

func _enter_tree():
	# If there are groups, use those instead.
	# This will be called before all the children register themselves.
	if self.light_groups:
		self._groups = []
		for g in self.light_groups.split(","):
			self._groups.append(g.strip_edges())

func _ready():
	assert(self.texture, "MPFShowCreator node requires a playfield image as a texture.")
	ProjectSettings.set_setting("display/window/size/window_width_override", self.texture.get_width())
	ProjectSettings.set_setting("display/window/size/window_height_override", self.texture.get_height())
	set_process(false)

	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		printerr("Error loading config file: %s" % err)
		return
	if config.has_section("show_creator") and config.has_section_key("show_creator", "animation"):
			animation_name = config.get_value("show_creator", "animation")

	assert(animation_name, "No animation name found in configuration.")
	assert(animation_player, "No AnimationPlayer node attached to the MPFShowGenerator root.")
	assert(animation_player.has_animation(animation_name), "AnimationPlayer has no animation named '%s'" % animation_name)

	if not self.lights:
		if self._groups:
			printerr("No lights found matching the selected groups.")
		else:
			printerr("No lights found. Please add some MPFShowLight nodes.")
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
	if light.position.x < 0 or light.position.y < 0 or light.position.x > self.texture.get_width() or light.position.y > self.texture.get_height():
		printerr("Light %s is outside of the viewport and will not be included." % self.name)
		return
	if self._groups:
		var has_match = false
		for g in self._groups:
			if light.is_in_group(g):
				has_match = true
				break
		if not has_match:
			return
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
