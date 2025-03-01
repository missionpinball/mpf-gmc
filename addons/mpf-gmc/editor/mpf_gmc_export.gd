# Plugin for exporting GMC projects with a pre-traversed
# list of media assets.
extends EditorExportPlugin

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:

#func _export_tree():
	# Ensure that the media has been traversed,
	# e.g. if this is being exported from CLI
	var mpf = preload("res://addons/mpf-gmc/mpf_gmc.gd").new()
	mpf.media.generate_traversal()

	var traversal = {
		"slides": mpf.media.slides,
		"sounds": mpf.media.sounds,
		"widgets": mpf.media.widgets,
	}

	var traversal_data = PackedDataContainer.new()
	traversal_data.pack(traversal)
	ResourceSaver.save(traversal_data, "res://_media.res")

func _export_end() -> void:
	# Remove the temporary media traversal file
	var d = DirAccess.open("res://")
	d.remove("res://_media.res")

func _get_name() -> String:
	return "GMC Exporter"
