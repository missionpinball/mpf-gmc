@tool
extends Control

const CONFIG_PATH = "user://mpf_show_creator.cfg"
const DEFAULT_SHOW =  "res://show_creator.tscn"

var config: ConfigFile
var lights: = {}
var tags: = {}
var verbose: bool = false

@onready var button_mpf_config = $MainVContainer/TopHContainer/LeftVContainer/container_mpf_config/button_mpf_config
@onready var edit_mpf_config = $MainVContainer/TopHContainer/LeftVContainer/container_mpf_config/edit_mpf_config
@onready var button_show_scene = $MainVContainer/TopHContainer/LeftVContainer/container_show_scene/button_show_scene
@onready var edit_show_scene = $MainVContainer/TopHContainer/LeftVContainer/container_show_scene/edit_show_scene

@onready var edit_fps = $MainVContainer/TopHContainer/LeftVContainer/BottomFContainer/container_fps/edit_fps
@onready var button_strip_lights = $MainVContainer/TopHContainer/LeftVContainer/BottomFContainer/button_strip_lights
@onready var button_strip_times = $MainVContainer/TopHContainer/LeftVContainer/BottomFContainer/button_strip_times
@onready var button_use_alpha = $MainVContainer/TopHContainer/LeftVContainer/BottomFContainer/button_use_alpha
@onready var button_verbose = $MainVContainer/TopHContainer/LeftVContainer/BottomFContainer/button_verbose


@onready var button_generate_lights = $MainVContainer/TopHContainer/LeftVContainer/container_generators/button_generate_lights
@onready var button_generate_scene = $MainVContainer/TopHContainer/LeftVContainer/container_generators/button_generate_scene
@onready var button_save_light_positions = $MainVContainer/TopHContainer/LeftVContainer/container_generators/button_save_light_positions
@onready var button_refresh_animations = $MainVContainer/TopHContainer/LeftVContainer/container_generators/button_refresh_animations


@onready var tags_container = $MainVContainer/TopHContainer/CenterVContainer/ScrollContainer/tag_checks
@onready var button_tags_select_all = $MainVContainer/TopHContainer/CenterVContainer/TagsHContainer/button_tags_select_all
@onready var button_tags_deselect_all = $MainVContainer/TopHContainer/CenterVContainer/TagsHContainer/button_tags_deselect_all

@onready var animation_dropdown = $MainVContainer/TopHContainer/RightVContainer/button_animation_names
@onready var button_show_maker = $MainVContainer/TopHContainer/RightVContainer/button_generate_show
@onready var button_preview_show = $MainVContainer/TopHContainer/RightVContainer/button_preview_show

func _ready():
	self.config = ConfigFile.new()
	var err = self.config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		printerr("Error loading config file: %s" % err)

	if self.config.has_section("show_creator"):
		if self.config.has_section_key("show_creator", "verbose"):
			button_verbose.button_pressed = self.config.get_value("show_creator", "verbose")
			verbose = button_verbose.button_pressed
		if self.config.has_section_key("show_creator", "mpf_config"):
			edit_mpf_config.text = self.config.get_value("show_creator", "mpf_config")
			if edit_mpf_config.text:
				debug_log("Found MPF config file '%s'" % edit_mpf_config.text)
				self.parse_mpf_config()
		if self.config.has_section_key("show_creator", "show_scene"):
			var scene_path = self.config.get_value("show_creator", "show_scene")
			if FileAccess.file_exists(scene_path):
				edit_show_scene.text = scene_path
				debug_log("Found Show Scene '%s'" % edit_show_scene.text)
				self._get_animation_names()
			else:
				self._save_show_scene("")
		if self.config.has_section_key("show_creator", "strip_lights"):
			button_strip_lights.button_pressed = self.config.get_value("show_creator", "strip_lights", true)
		if self.config.has_section_key("show_creator", "strip_times"):
			button_strip_times.button_pressed = self.config.get_value("show_creator", "strip_times", true)
		if self.config.has_section_key("show_creator", "use_alpha"):
			button_use_alpha.button_pressed = self.config.get_value("show_creator", "use_alpha", false)

	# Set the listeners *after* the initial values are set
	button_mpf_config.pressed.connect(self._select_mpf_config)
	button_show_scene.pressed.connect(self._select_show_scene)
	button_generate_lights.pressed.connect(self._generate_lights)
	button_generate_scene.pressed.connect(self._generate_scene)
	button_save_light_positions.pressed.connect(self._save_light_positions)
	edit_mpf_config.text_submitted.connect(self._save_mpf_config)
	edit_show_scene.text_submitted.connect(self._save_show_scene)
	button_show_maker.pressed.connect(self._generate_show)
	button_preview_show.pressed.connect(self._preview_show)
	animation_dropdown.item_selected.connect(self._select_animation)
	button_refresh_animations.pressed.connect(self._get_animation_names)

	# Tags
	button_tags_select_all.pressed.connect(self._select_all_tags)
	button_tags_deselect_all.pressed.connect(self._deselect_all_tags)

	# Configuration buttons
	button_strip_lights.toggled.connect(self._on_option.bind("strip_lights"))
	button_strip_times.toggled.connect(self._on_option.bind("strip_times"))
	button_use_alpha.toggled.connect(self._on_option.bind("use_alpha"))
	button_verbose.toggled.connect(self._on_option.bind("verbose"))

	self._render_generate_button()

	button_show_maker.disabled = animation_dropdown.item_count == 0

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
			if self.config.has_section_key("lights", l):
				light_child.restore(self.config.get_value("lights", l))
			else:
				light_child.global_position = Vector2(-1, -1)
			lights_node.add_child(light_child)
			light_child.owner = scene
		# Tags may have changed, so set that even on existing lights
		light_child.tags = self.lights[l].tags

	debug_log("Added %s lights to the scene %s" % [lights_node.get_child_count(), edit_show_scene.text])
	var pckscene = PackedScene.new()
	var result = pckscene.pack(scene)
	if result != OK:
		push_error("Error packing scene: %s" % error_string(result))
		return
	var err = ResourceSaver.save(pckscene, edit_show_scene.text)
	if err != OK:
		push_error("Error saving scene: %s" % error_string(err))
		return

	EditorInterface.reload_scene_from_path(edit_show_scene.text)

func _save_light_positions():
	EditorInterface.save_scene()
	var global_space = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	debug_log("Setting light positions on a %s x %s plane" % [global_space.x, global_space.y])

	var scene = load(edit_show_scene.text).instantiate()
	for l in self.lights.keys():
		var light = scene.find_child(l)
		debug_log("Checking light %s with node %s" % [l, light])
		if not light:
			push_warning("Light '%s' not found in scene" % l)
			continue
		if light.global_position == Vector2(-1, -1):
			debug_log("Light '%s' has not been positioned." % l)
			if self.config.has_section("lights") and self.config.has_section_key("lights", l):
				self.config.erase_section_key("lights", l)
			continue
		var settings = {
			"position": light.global_position / global_space,
			"shape": light.shape,
			"scale": light.scale,
			"rotation_degrees": light.rotation_degrees,
			"tags": self.lights[l]["tags"]
		}
		self.config.set_value("lights", l, settings)
	self.config.save(CONFIG_PATH)


func _generate_show():
	EditorInterface.play_custom_scene(edit_show_scene.text)

func _preview_show():
	EditorInterface.play_custom_scene("res://addons/mpf-show-creator/mpf_show_preview.tscn")

func _get_animation_names():
	EditorInterface.save_scene()
	animation_dropdown.clear()
	if not edit_show_scene.text:
		debug_log("No show scene selected, cannot find animations.")
		return
	var scene = load(edit_show_scene.text).instantiate()
	var animp = scene.animation_player
	var animations = animp.get_animation_list()
	if animations.has("RESET"):
		animations.remove_at(animations.find("RESET"))

	var selected_index = -1
	if self.config.has_section_key("show_creator", "animation") and self.config.get_value("show_creator", "animation", false):
		selected_index = animations.find(self.config.get_value("show_creator", "animation"))

	for a in animations:
		animation_dropdown.add_item(a)
	if selected_index != -1 and selected_index < animation_dropdown.item_count:
		animation_dropdown.select(selected_index)
		self._select_animation(selected_index)
	# If no selected index then none has been saved, so trigger a save
	elif animation_dropdown.item_count:
		self._select_animation(0)
	debug_log("Found %s animations: %s" % [animation_dropdown.item_count, animations])
	button_show_maker.disabled = animation_dropdown.item_count == 0

func _select_animation(idx: int):
	var animation_name = animation_dropdown.get_item_text(idx)

	# Update the tags list based on this animation
	if self.config.has_section_key("tags", animation_name):
		var include_tags = self.config.get_value("tags", animation_name)
		for tag_box in tags_container.get_children():
			tag_box.button_pressed = tag_box.text in include_tags
	else:
		self._select_all_tags()

	# If this is already the saved animation, no more to do
	if self.config.has_section_key("show_creator", "animation") and animation_name == self.config.get_value("show_creator", "animation"):
		return

	self.config.set_value("show_creator", "animation", animation_name)
	self.config.save(CONFIG_PATH)

func _select_all_tags():
	for tag_box in tags_container.get_children():
		tag_box.button_pressed = true
	self._save_tags()

func _deselect_all_tags():
	for tag_box in tags_container.get_children():
		tag_box.button_pressed = false
	self._save_tags()

func _save_tags(_toggle_state=false):
	# Check for tags to attach to this show
	var animation_name = animation_dropdown.get_item_text(animation_dropdown.selected)
	var included_tags = []
	var excluded_tags = []
	for tag in tags_container.get_children():
		if tag.button_pressed:
			included_tags.append(tag.text)
		else:
			excluded_tags.append(tag.text)
	# If any tags are excluded, store the included ones
	if excluded_tags:
		self.config.set_value("tags", animation_name, included_tags)
	elif self.config.has_section_key("tags", animation_name):
		self.config.erase_section_key("tags", animation_name)
	self.config.save(CONFIG_PATH)

func _generate_scene():
	var root = MPFShowCreator.new()
	root.name = "MPFShowCreator"
	root.centered = false
	# Look for a playfield file
	for f in ["res://playfield.png", "res://playfield.jpg"]:
		if FileAccess.file_exists(f):
			root.texture = load(f)
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
		push_error("Error packing scene: %s" % error_string(result))
		return
	var err = ResourceSaver.save(scene, DEFAULT_SHOW)
	if err != OK:
		push_error("Error saving scene: %s" % error_string(err))
		return

	self.config.set_value("show_creator", "show_scene", DEFAULT_SHOW)
	self.config.save(CONFIG_PATH)
	edit_show_scene.text = DEFAULT_SHOW

	if not self.lights.is_empty():
		self._generate_lights()
	self._render_generate_button()

	if DEFAULT_SHOW in EditorInterface.get_open_scenes():
		EditorInterface.reload_scene_from_path(DEFAULT_SHOW)
	else:
		EditorInterface.open_scene_from_path(DEFAULT_SHOW)


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
	self.config.set_value("show_creator", opt_name, pressed)
	self.config.save(CONFIG_PATH)
	if opt_name == "verbose":
		verbose = pressed

func parse_mpf_config():
	debug_log("Parsing MPF config at %s" % edit_mpf_config.text)
	var mpf_config = FileAccess.open(edit_mpf_config.text, FileAccess.READ)
	var line = mpf_config.get_line()
	var is_in_lights = false
	var current_light: String
	var delimiter: String
	var delimiter_size: int
	while mpf_config.get_position() < mpf_config.get_length():
		var line_stripped = line.get_slice("#", 0).strip_edges()
		if not line_stripped:
			line = mpf_config.get_line()
			continue
		if line_stripped == "lights:":
			debug_log(" - Found 'lights:' section!")
			is_in_lights = true
			# The next line will give us our delimiter
			line = mpf_config.get_line()
			line_stripped = line.get_slice("#", 0).strip_edges()
			# ...unless the next line is blank or a comment
			while not line_stripped:
				line = mpf_config.get_line()
				line_stripped = line.get_slice("#", 0).strip_edges()
			var dedent = line.dedent()
			delimiter_size = line.length() - dedent.length()
			delimiter = line.substr(0, delimiter_size)

		if is_in_lights:
			var line_data = line_stripped.split(":")
			var indent_check = line.substr(delimiter_size).length() - line.strip_edges(true, false).length()
			# If the check is zero, there is one delimiter and this is a new light
			if indent_check == 0:
				current_light = line_data[0]
				debug_log(" - Found a light '%s'" % current_light)
				lights[current_light] = { "tags": []}
			# If the check is larger, there is more than a delimiter and this is part of the light
			elif indent_check > 0:
				# Clear out any inline comments and extra whitespace
				if line_data[0] == "tags":
					for t in line_data[1].split(","):
						var tag = t.strip_edges()
						if not self.tags.has(tag):
							self.tags[tag] = []
						self.tags[tag].append(current_light)
						lights[current_light]["tags"].append(tag)
			# If the check is smaller, there is less than a delimiter and we are done with lights
			else:
				is_in_lights = false
		line = mpf_config.get_line()

	for n in tags_container.get_children():
		tags_container.remove_child(n)
		n.queue_free()
	if not self.tags.is_empty():
		debug_log("Found the following tags: %s" % ", ".join(self.tags.keys()))
		for tag in self.tags.keys():
			var tag_box = CheckBox.new()
			tag_box.text = tag
			tag_box.button_pressed = true
			tag_box.toggled.connect(self._save_tags)
			tags_container.add_child(tag_box)


func debug_log(message: String):
	if verbose:
		print_debug(message)
