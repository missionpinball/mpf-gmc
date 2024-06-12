@tool
extends Control

const CONFIG_PATH = "user://mpf_show_creator.cfg"

var config: ConfigFile
var lights: = {}

@onready var button_mpf_config = $VBoxContainer/container_mpf_config/button_mpf_config
@onready var edit_mpf_config = $VBoxContainer/container_mpf_config/edit_mpf_config

func _ready():
	button_mpf_config.pressed.connect(self._select_mpf_config)
	self.config = ConfigFile.new()
	var err = self.config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		printerr("Error loading config file: %s" % err)

	if self.config.has_section("show_creator"):
		if self.config.has_section_key("show_creator", "mpf_config"):
			edit_mpf_config.text = self.config.get_value("show_creator", "mpf_config")
			self.parse_mpf_config()

func _select_mpf_config():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	self.add_child(dialog)
	dialog.popup_centered(Vector2i(400, 400))
	var path = await dialog.file_selected
	if not path:
		return
	self.config.set_value("show_creator", "mpf_config", path)
	edit_mpf_config.text = path
	self.config.save(CONFIG_PATH)
	self.parse_mpf_config()

func parse_mpf_config():
	var mpf_config = FileAccess.open(edit_mpf_config.text, FileAccess.READ)
	var line = mpf_config.get_line()
	var is_in_lights = false
	var current_light: String
	var delimiter: String
	var delimiter_size: int
	while mpf_config.get_position() < mpf_config.get_length():
		if line.strip_edges() == "lights:":
			is_in_lights = true
			# The next line will give us our delimiter
			line = mpf_config.get_line()
			var dedent = line.dedent()
			delimiter_size = line.length() - dedent.length()
			delimiter = line.substr(0, delimiter_size)
			print("DELIMITER: '%s'" % delimiter)

		if is_in_lights:
			var line_data = line.strip_edges().split(":")
			var indent_check = line.substr(delimiter_size).length() - line.strip_edges(true, false).length()
			# If the check is zero, there is one delimiter and this is a new light
			if indent_check == 0:
				current_light = line_data[0]
				lights[current_light] = {}
				print("Found light %s" % current_light)
			# If the check is larger, there is more than a delimiter and this is part of the light
			elif indent_check > 0:
				if line_data[0] == "tags":
					lights[current_light]["tags"] = []
					for t in line_data[1].split(","):
						lights[current_light]["tags"].append(t.strip_edges())
					print(" - tags: %s" % " and ".join(lights[current_light]["tags"]))
			# If the check is smaller, there is less than a delimiter and we are done with lights
			else:
				is_in_lights = false
		line = mpf_config.get_line()