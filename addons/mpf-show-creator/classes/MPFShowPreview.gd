extends Node2D
class_name MPFShowPreview

const CONFIG_PATH = "user://mpf_show_creator.cfg"
const LOOP_SHOW_DELAY_SECS = 1.0

var config: ConfigFile
var animation_name: String
var scene: MPFShowCreator
var time := 0.0

var duration: float
var timestamps: Array
var light_steps: Array
var lights: Dictionary = {}

var step_idx := 0
var next_timestamp: float = 0.0

func _enter_tree():
	config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		assert(false, "Error loading config file: %s" % err)
		return
	if not config.has_section("show_creator"):
		assert(false, "Unable to read correct fields from config file: %s" % error_string(err))

	timestamps = config.get_value("preview", "timestamps")
	light_steps = config.get_value("preview", "light_steps")
	duration = config.get_value("preview", "duration")
	animation_name = config.get_value("preview", "show")
	var scene_path = config.get_value("show_creator", "show_scene")
	scene = load(scene_path).instantiate()
	self.add_child(scene)

	# Just in case the show doesn't start at zero
	next_timestamp = timestamps[0]

func _ready():
	# Create a dictionary to quickly look up lights
	for l in scene.lights:
		self.lights[l.name] = l
		l.visible = true
		# Even lights not used in this show should be cleared
		l.set_color(Color(0,0,0,0))

func _process(delta):
	time = time + delta
	if time < next_timestamp:
		return

	self.populate_step(step_idx)
	step_idx += 1
	# If we've finished all the timestamps
	if step_idx >= timestamps.size():
		step_idx = 0
		# Delay for a moment before looping
		time = time - duration - LOOP_SHOW_DELAY_SECS
	next_timestamp = timestamps[step_idx]

func populate_step(idx: int):
	var step_lights = light_steps[idx]
	for light_name in step_lights.keys():
		self.lights[light_name].set_color(step_lights[light_name])

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_class("InputEventKey"):
		return
	# Don't support holding down a key
	if event.is_echo():
		return
	var keycode = OS.get_keycode_string(event.get_key_label_with_modifiers()).to_upper()
	if keycode == "ESCAPE":
		if not event.is_pressed():
			return
		get_tree().notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
