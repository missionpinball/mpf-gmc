extends Node2D
class_name MPFMonitor

const CONFIG_PATH = "user://mpf_show_creator.cfg"

var server
var scene
var config: ConfigFile

var players = []
var machine_vars = {}
var lights = {}
var modes = []

func _enter_tree() -> void:
	config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		assert(false, "Error loading config file: %s" % err)
		return
	if not config.has_section("show_creator"):
		assert(false, "Unable to read correct fields from config file: %s" % error_string(err))

	var scene_path = config.get_value("show_creator", "show_scene")
	scene = load(scene_path).instantiate()
	self.add_child(scene)
	server = preload("res://addons/mpf-show-creator/classes/monitor_server.gd").new()
	self.add_child(server)

func _ready():
	server.switch.connect(self._on_switch)
	server.light.connect(self._on_light)
	server.update_device.connect(self._update_device)
	server.update_machine_var.connect(self._update_machine_var)
	server.update_player_var.connect(self._update_player_var)
	server.update_modes.connect(self._update_modes)
	server.player_added.connect(self._add_player)

	for l in scene.lights:
		self.lights[l.name] = l
		l.set_color(Color(0.0,0.0,0.0))


func _on_light(payload):
	if not payload.name in self.lights:
		printerr("Unknown light named '%s'" % payload.name)
		return
	var colors = payload.state.color
	self.lights[payload.name].set_color(Color(colors[0], colors[1], colors[2]))

func _on_switch(payload):
	print("SWITCH: %s" % payload)

func _add_player():
	self.players.append({})

func _update_device(payload):
	if payload.type == "light":
		self._on_light(payload)

func _update_machine_var(var_name, value):
	self.machine_vars[var_name] = value

func _update_player_var(var_name, value, num):
	if num > self.players.size():
		self.players.append({})
	self.players[num][var_name] = value

func _update_modes(payload):
	print("MODES: %s" % payload)
	self.modes = payload.running_modes
