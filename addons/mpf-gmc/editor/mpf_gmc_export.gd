@tool
extends EditorExportPlugin

class GMCTraversal extends Resource:
	var slides: Dictionary
	var sounds: Dictionary
	var widgets: Dictionary

	func _init(sl, so, wi):
		slides = sl
		sounds = so
		widgets = wi

	func _to_string() -> String:
		return "{ slides: %s, sounds: %s, widgets: %s }" % [slides, sounds, widgets]

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	print("Beginning export with features:")
	print(features)
	features.append("gmc_export")

	# Unknown if ConfigFile has a binary representation that will work with add_file
	# var traversal_map := ConfigFile.new()
	# for media in ["slides", "widgets", "sounds"]:
	# 	traversal_map.set_value("traversal", media, MPF.media[media])
	# add_file("res://media.cfg", traversal_map)

	# var traversal = {}
	# for media in ["slides", "widgets", "sounds"]:
	# 	traversal[media] = MPF.media[media]
	# add_file("res://media.json", JSON.stringify(traversal))

	# var traversal = GMCTraversal.new(MPF.media.slides, MPF.media.sounds, MPF.media.widgets)
	var traversal = {
		"slides": MPF.media.slides,
		"sounds": MPF.media.sounds,
		"widgets": MPF.media.widgets,
	}
	# var traversal_bytes = PackedByteArray()
	# traversal_bytes.encode_var(0, traversal, true)
	var traversal_bytes = PackedDataContainer.new()
	traversal_bytes.pack(traversal)
	print("Traversal: %s" % traversal)
	print("Traversal bytes: %s" % traversal_bytes)
	# add_file("res://media.res", traversal_bytes, false)
	ResourceSaver.save(traversal_bytes, "res://media.res")

func _get_name() -> String:
	return "GMC Exporter"