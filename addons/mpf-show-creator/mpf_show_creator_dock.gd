@tool
extends Control

const CONFIG_PATH = "user://mpf_show_creator.cfg"
const DEFAULT_SHOW =  "res://show_creator.tscn"

var config: ConfigFile
var lights: = {}

@onready var button_mpf_config = $HBoxContainer/LeftVContainer/container_mpf_config/button_mpf_config
@onready var edit_mpf_config = $HBoxContainer/LeftVContainer/container_mpf_config/edit_mpf_config
@onready var button_show_scene = $HBoxContainer/LeftVContainer/container_show_scene/button_show_scene
@onready var edit_show_scene = $HBoxContainer/LeftVContainer/container_show_scene/edit_show_scene

@onready var edit_fps = $HBoxContainer/CenterVContainer/container_fps/edit_fps
@onready var button_strip_lights = $HBoxContainer/CenterVContainer/button_strip_lights
@onready var button_strip_times = $HBoxContainer/CenterVContainer/button_strip_times
@onready var button_use_alpha = $HBoxContainer/CenterVContainer/button_use_alpha

@onready var button_generate_lights = $HBoxContainer/LeftVContainer/container_generators/button_generate_lights
@onready var button_generate_scene = $HBoxContainer/LeftVContainer/container_generators/button_generate_scene
@onready var button_refresh_animations = $HBoxContainer/LeftVContainer/container_generators/button_refresh_animations

@onready var animation_dropdown = $HBoxContainer/RightVContainer/button_animation_names
@onready var button_show_maker = $HBoxContainer/RightVContainer/button_generate_show

func _ready():
	self.config = ConfigFile.new()
	var err = self.config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		printerr("Error loading config file: %s" % err)

	if self.config.has_section("show_creator"):
		if self.config.has_section_key("show_creator", "mpf_config"):
			edit_mpf_config.text = self.config.get_value("show_creator", "mpf_config")
			if edit_mpf_config.text:
				self.parse_mpf_config()
		if self.config.has_section_key("show_creator", "show_scene"):
			edit_show_scene.text = self.config.get_value("show_creator", "show_scene")
			self._get_animation_names()
		if self.config.has_section_key("show_creator", "strip_lights"):
			button_strip_lights.button_pressed = self.config.get_value("show_creator", "strip_lights")
		if self.config.has_section_key("show_creator", "strip_times"):
			button_strip_times.button_pressed = self.config.get_value("show_creator", "strip_times")
		if self.config.has_section_key("show_creator", "use_alpha"):
			button_use_alpha.button_pressed = self.config.get_value("show_creator", "use_alpha")

	# Set the listeners *after* the initial values are set
	button_mpf_config.pressed.connect(self._select_mpf_config)
	button_show_scene.pressed.connect(self._select_show_scene)
	button_generate_lights.pressed.connect(self._generate_lights)
	button_generate_scene.pressed.connect(self._generate_scene)
	edit_mpf_config.text_submitted.connect(self._save_mpf_config)
	edit_show_scene.text_submitted.connect(self._save_show_scene)
	button_show_maker.pressed.connect(self._generate_show)
	animation_dropdown.item_selected.connect(self._select_animation)
	button_refresh_animations.pressed.connect(self._get_animation_names)

	button_strip_lights.toggled.connect(self._on_option.bind("strip_lights"))
	button_strip_times.toggled.connect(self._on_option.bind("strip_times"))
	button_use_alpha.toggled.connect(self._on_option.bind("use_alpha"))

	self._render_generate_button()

func _generate_lights(lights_node: Node2D = null):
	if self.lights.is_empty():
		printerr("No light configuration found.")
		return
	var scene = load(edit_show_scene.text).instantiate()
	# Look for a lights child node
	if not lights_node:
		lights_node = scene.get_node_or_null("lights")
	if not lights_node:
		lights_node = Node2D.new()
		lights_node.name = "lights"
		scene.add_child(lights_node)
		lights_node.owner = scene
	for l in self.lights.keys():
		var light_child = scene.find_child(l)
		if not light_child:
			light_child = MPFShowLight.new()
			light_child.name = l
			light_child.position = Vector2(-1, -1)
			lights_node.add_child(light_child)
			light_child.owner = scene
		if not self.lights[l]["tags"]:
			for t in self.lights[l].tags:
				light_child.add_to_group(t, true)

	var pckscene = PackedScene.new()
	var result = pckscene.pack(scene)
	if result != OK:
		push_error("Error packing scene: %s" % result)
		return
	var err = ResourceSaver.save(pckscene, edit_show_scene.text)
	if err != OK:
		push_error("Error saving scene: %s" % err)
		return

func _generate_show():
	EditorInterface.play_custom_scene(edit_show_scene.text)

func _get_animation_names():
	animation_dropdown.clear()
	if not edit_show_scene.text:
		return
	var scene = load(edit_show_scene.text).instantiate()
	var animp = scene.animation_player
	var animations = animp.get_animation_list()

	var selected_index = -1
	if self.config.has_section_key("show_creator", "animation"):
		selected_index = animations.find(self.config.get_value("show_creator", "animation"))

	for a in animations:
		if a == "RESET":
			continue
		animation_dropdown.add_item(a)

	if selected_index != -1:
		animation_dropdown.select(selected_index)
	# If no selected index then none has been saved, so trigger a save
	else:
		self._select_animation(0)

func _select_animation(idx: int):
	var animation_name = animation_dropdown.get_item_text(idx)

	if self.config.has_section_key("show_creator", "animation") and animation_name == self.config.get_value("show_creator", "animation"):
		return

	self.config.set_value("show_creator", "animation", animation_name)
	self.config.save(CONFIG_PATH)

func _generate_scene():
	var root = MPFShowCreator.new()
	root.name = "MPFShowCreator"
	root.centered = false
	var animp = AnimationPlayer.new()
	animp.name = "AnimationPlayer"
	root.add_child(animp)
	root.animation_player = animp
	animp.owner = root
	var lights_node = Node2D.new()
	lights_node.name = "lights"
	root.add_child(lights_node)
	lights_node.owner = root

	var scene = PackedScene.new()
	var result = scene.pack(root)
	if result != OK:
		push_error("Error packing scene: %s" % result)
		return
	var err = ResourceSaver.save(scene, DEFAULT_SHOW)
	if err != OK:
		push_error("Error saving scene: %s" % err)
		return

	self.config.set_value("show_creator", "show_scene", DEFAULT_SHOW)
	self.config.save(CONFIG_PATH)
	edit_show_scene.text = DEFAULT_SHOW

	if not self.lights.is_empty():
		self._generate_lights()

func _select_mpf_config():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	self.add_child(dialog)
	dialog.popup_centered(Vector2i(1100, 900))
	var path = await dialog.file_selected
	self._save_mpf_config(path)

func _save_mpf_config(path):
	self.config.set_value("show_creator", "mpf_config", path)
	edit_mpf_config.text = path
	self.config.save(CONFIG_PATH)
	if path:
		self.parse_mpf_config()
	self._render_generate_button()

func _select_show_scene():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES
	self.add_child(dialog)
	dialog.popup_centered(Vector2i(1100, 900))
	var path = await dialog.file_selected
	self._save_show_scene(path)

func _save_show_scene(path):
	self.config.set_value("show_creator", "show_scene", path)
	edit_show_scene.text = path
	self.config.save(CONFIG_PATH)
	if path:
		self._get_animation_names()
	self._render_generate_button()

func _render_generate_button():
	if edit_show_scene.text:
		button_generate_scene.visible = false
		button_generate_lights.visible = true
	else:
		button_generate_lights.visible = false
		button_generate_scene.visible = true
	button_generate_scene.disabled = self.lights.is_empty()

func _on_option(pressed, opt_name):
	print("Got option pressed state %s and name %s" % [pressed, opt_name])
	self.config.set_value("show_creator", opt_name, pressed)
	self.config.save(CONFIG_PATH)

func parse_mpf_config():
	var mpf_config = FileAccess.open(edit_mpf_config.text, FileAccess.READ)
	var line = mpf_config.get_line()
	var is_in_lights = false
	var current_light: String
	var delimiter: String
	var delimiter_size: int
	while mpf_config.get_position() < mpf_config.get_length():
		var line_stripped = line.strip_edges()
		if not line_stripped or line_stripped.begins_with("#"):
			line = mpf_config.get_line()
			continue
		if line_stripped == "lights:":
			is_in_lights = true
			# The next line will give us our delimiter
			line = mpf_config.get_line()
			var dedent = line.dedent()
			delimiter_size = line.length() - dedent.length()
			delimiter = line.substr(0, delimiter_size)

		if is_in_lights:
			var line_data = line_stripped.split(":")
			var indent_check = line.substr(delimiter_size).length() - line.strip_edges(true, false).length()
			# If the check is zero, there is one delimiter and this is a new light
			if indent_check == 0:
				current_light = line_data[0]
				lights[current_light] = { "tags": []}
			# If the check is larger, there is more than a delimiter and this is part of the light
			elif indent_check > 0:
				if line_data[0] == "tags":
					for t in line_data[1].split(","):
						lights[current_light]["tags"].append(t.strip_edges())
			# If the check is smaller, there is less than a delimiter and we are done with lights
			else:
				is_in_lights = false
		line = mpf_config.get_line()