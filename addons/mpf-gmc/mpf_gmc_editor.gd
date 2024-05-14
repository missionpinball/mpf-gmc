@tool
extends EditorPlugin

var dock

func _enter_tree():
	var theme = EditorInterface.get_editor_theme()
	#print(theme.get_icon_list("EditorIcons"))
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("MPFChildPool", "Node2D", preload("classes/mpf_child_pool.gd"), theme.get_icon("BackBufferCopy", "EditorIcons"))
	add_custom_type("MPFSceneBase", "Node2D", preload("classes/mpf_scene_base.gd"), null)
	add_custom_type("MPFWidget", "Node2D", preload("classes/mpf_widget.gd"), null)
	add_custom_type("MPFWindow", "Node2D", preload("classes/mpf_window.gd"), null)
	add_custom_type("MPFDisplay", "MPFSceneBase", preload("classes/mpf_display.gd"), null)
	add_custom_type("MPFSlide", "MPFSceneBase", preload("classes/mpf_slide.gd"), null)
	add_custom_type("MPFVariable", "Label", preload("classes/mpf_variable.gd"), null)
	add_custom_type("MPFCarousel", "Node2D", preload("classes/mpf_carousel.gd"), theme.get_icon("DampedSpringJoint2D", "EditorIcons"))
	add_custom_type("MPFVideoPlayer", "VideoStreamPlayer", preload("classes/mpf_video_player.gd"), null)
	add_custom_type("MPFSoundAsset", "Resource", preload("classes/mpf_sound.gd"), null)
	add_custom_type("MPFLogger", "Node", preload("classes/mpf_logger.gd"), theme.get_icon("AcceptDialog", "EditorIcons"))
	add_custom_type("MPFEventHandler", "Node2D", preload("classes/mpf_event_handler.gd"), theme.get_icon("RemoteTransform2D", "EditorIcons"))
	add_custom_type("MPFConditional", "Node2D", preload("classes/mpf_conditional.gd"), theme.get_icon("MeshInstance2D", "EditorIcons"))
	add_custom_type("MPFConditionalChildren", "Node2D", preload("classes/mpf_conditional_children.gd"), theme.get_icon("MultiMeshInstance2D", "EditorIcons"))

	# Create a custom dock for GMC Settings
	dock = preload("res://addons/mpf-gmc/editor/gmc_panel.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)

func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	remove_custom_type("MPFChildPool")
	remove_custom_type("MPFSceneBase")
	remove_custom_type("MPFWidget")
	remove_custom_type("MPFDisplay")
	remove_custom_type("MPFWindow")
	remove_custom_type("MPFSlide")
	remove_custom_type("MPFVariable")
	remove_custom_type("MPFCarousel")
	remove_custom_type("MPFVideoPlayer")
	remove_custom_type("MPFSoundAsset")
	remove_custom_type("MPFLogger")
	remove_custom_type("MPFEventHandler")
	remove_custom_type("MPFConditional")
	remove_custom_type("MPFConditionalChildren")

	remove_control_from_docks(dock)
	dock.free()
