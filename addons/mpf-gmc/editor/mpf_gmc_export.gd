@tool
extends EditorExportPlugin

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	# Ensure that the media has been traversed,
	# e.g. if this is being exported from CLI
	MPF.media.generate_traversal()

	var traversal = {
		"slides": MPF.media.slides,
		"sounds": MPF.media.sounds,
		"widgets": MPF.media.widgets,
	}

	var traversal_bytes = PackedDataContainer.new()
	traversal_bytes.pack(traversal)
	ResourceSaver.save(traversal_bytes, "res://_media.res")

func _export_end() -> void:
	var d = DirAccess.open("res://")
	d.remove("res://_media.res")

func _get_name() -> String:
	return "GMC Exporter"