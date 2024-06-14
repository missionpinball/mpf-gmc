@tool
extends EditorPlugin

var show_creator_dock

func _enter_tree():
	var version = Engine.get_version_info()
	if version.major < 4 or version.minor < 2:
		push_error("MPF Show Creator requires Godot version 4.2 or later, you have %s.%s.%s. Please visit godotengine.org to update." % [version.major, version.minor, version.patch])
		return
	add_custom_type("MPFShowCreator", "Sprite2D", preload("classes/MPFShowCreator.gd"), preload("icons/Camera2D.svg"))
	add_custom_type("MPFShowLight", "Node2D", preload("classes/MPFShowLight.gd"), preload("icons/DirectionalLight2D.svg"))
	show_creator_dock = preload("res://addons/mpf-show-creator/mpf_show_creator_dock.tscn").instantiate()
	add_control_to_bottom_panel(show_creator_dock, "MPF Show Creator")

func _exit_tree():
	remove_custom_type("MPFShowCreator")
	remove_custom_type("MPFShowLight")
	remove_control_from_bottom_panel(show_creator_dock)
