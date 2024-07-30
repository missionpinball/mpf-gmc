# Base singleton for managing all MC-related references,
# including windows, displays, slides, and widgets
extends LoggingNode
class_name GMCMedia

var sound: Node
var window: Node
var slides := {}
var widgets := {}
var sounds := {}

func _enter_tree() -> void:
	# Look for an exported traversal file
	if ResourceLoader.exists("res://_media.res"):
		self.log.info("Retrieving exported media tree traversal.")
		# Cannot use preload because the file may not exist
		var traversal = load("res://_media.res")
		for m in ["slides", "sounds", "widgets"]:
			for k in traversal[m]:
				self[m][k] = traversal[m][k]
	else:
		self.log.info("Traversing directory tree for media.")
		self.generate_traversal()

	self.log.debug("Generated slide lookups: %s", slides)
	self.log.debug("Generated widget lookups: %s", widgets)
	self.log.debug("Generated sound lookups: %s", sounds)

	sound = preload("sound_player.gd").new()

	# Process is only called on children in the tree, so add the children
	# that need to call process
	self.add_child(sound)

func register_window(inst: Node) -> void:
	window = inst

func play(payload: Dictionary) -> void:
	var command = payload.name
	match command:
		"buses_play":
			self.sound.play_bus(payload)
		"slides_play":
			self.window.play_slides(payload)
		"widgets_play":
			self.window.play_widgets(payload)
		"sounds_play":
			self.sound.play_sounds(payload)

func get_slide_instance(slide_name: String, preload_only: bool = false) -> MPFSlide:
	assert(slide_name in slides, "Unknown slide name '%s'" % slide_name)
	return self._get_scene(slide_name, self.slides, preload_only) as MPFSlide

func get_widget_instance(widget_name: String, preload_only: bool = false) -> MPFWidget:
	assert(widget_name in widgets, "Unknown widget name '%s'" % widget_name)
	return self._get_scene(widget_name, self.widgets, preload_only) as MPFWidget

func get_sound_instance(sound_name: String, preload_only: bool = false):
	assert(sound_name in sounds, "Unknown sound name '%s'" % sound_name)
	return self._get_scene(sound_name, self.sounds, preload_only)

func generate_traversal() -> void:
	slides = {}
	widgets = {}
	sounds = {}
	self.traverse_tree_for("slides", slides)
	self.traverse_tree_for("widgets", widgets)
	# Always do TRES files last so they'll supersede WAV/OGG files of the same name
	for ext in ["mp3", "wav", "ogg", "tres"]:
		self.traverse_tree_for("sounds", sounds, ext)

func _get_scene(scene_name: String, collection: Dictionary, preload_only: bool = false):
	# If this is the first access, load the scene
	if collection[scene_name] is String:
		collection[scene_name] = load(collection[scene_name])
	if preload_only:
		return
	if collection == self.sounds:
		return collection[scene_name]
	return collection[scene_name].instantiate()

func traverse_tree_for(obj_type: String, acc: Dictionary, ext="tscn") -> void:
	# Look for a specified content root
	var content_root: String = "res://%s" % obj_type
	if MPF.has_config_section("gmc"):
		var root = MPF.get_config_value("gmc", "content_root", "")
		if root:
			content_root = "res://%s/%s" % [root, obj_type]
	# Start by traversing the root folder for this object type
	self.recurse_dir(content_root, acc, ext)
	self.recurse_modes(obj_type, acc, ext)
	# Then look for defaults included with GMC
	var defaults = {}
	self.recurse_dir("res://addons/mpf-gmc/%s" % obj_type, defaults, ext)
	# And map over to fill in defaults for any missing scenes
	for d in defaults:
		if d not in acc:
			acc[d] = defaults[d]

func recurse_dir(path, acc, ext="tscn") -> void:
	var dir = DirAccess.open(path)
	# If this path does not exist, that's okay
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while (file_name != ""):
		if dir.current_is_dir():
			self.recurse_dir("%s/%s" % [path, file_name], acc, ext)
		elif file_name.ends_with(".%s" % ext):
			acc[file_name.rsplit(".", false, 1)[0]] = "%s/%s" % [path, file_name]
		file_name = dir.get_next()

func recurse_modes(obj_type: String, acc: Dictionary, ext="tscn") -> void:
	# Traverse the mode folders for subfolders of this object type
	var dir = DirAccess.open("res://modes")
	# If this is a new project there may not be modes
	if not dir:
		return
	dir.list_dir_begin()
	var mode = dir.get_next()
	while (mode != ""):
		var mdir = DirAccess.open("res://modes/%s" % mode)
		if mdir:
			mdir.list_dir_begin()
			var file_name = mdir.get_next()
			while (file_name != ""):
				if file_name == obj_type and mdir.current_is_dir():
					self.recurse_dir("res://modes/%s/%s" % [mode, obj_type], acc, ext)
				file_name = mdir.get_next()
		mode = dir.get_next()
