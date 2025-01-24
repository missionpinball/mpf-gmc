@tool
extends EditorPlugin

var gmc_dock
var mpf_dock
var mpf_output
var mpf_launch
var mpf_debugger
var gmc_export

func _enter_tree():
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("MPFChildPool", "Control", preload("classes/mpf_child_pool.gd"), preload("icons/BackBufferCopy.svg"))
	add_custom_type("MPFSceneBase", "Control", preload("classes/mpf_scene_base.gd"), preload("icons/Node.svg"))
	add_custom_type("MPFTextInput", "HFlowContainer", preload("classes/mpf_text_input.gd"), preload("icons/Keyboard.svg"))
	add_custom_type("MPFWidget", "Control", preload("classes/mpf_widget.gd"), preload("icons/ReferenceRect.svg"))
	add_custom_type("MPFWindow", "Control", preload("classes/mpf_window.gd"), preload("icons/WorldEnvironment.svg"))
	add_custom_type("MPFDisplay", "MPFSceneBase", preload("classes/mpf_display.gd"), preload("icons/PhysicalSkyMaterial.svg"))
	add_custom_type("MPFSlide", "MPFSceneBase", preload("classes/mpf_slide.gd"), preload("icons/Window.svg"))
	add_custom_type("MPFVariable", "Label", preload("classes/mpf_variable.gd"), preload("icons/Label.svg"))
	add_custom_type("MPFCarousel", "Control", preload("classes/mpf_carousel.gd"), preload("icons/GridLayout.svg"))
	add_custom_type("MPFVideoPlayer", "VideoStreamPlayer", preload("classes/mpf_video_player.gd"), preload("icons/VideoStreamPlayer.svg"))
	add_custom_type("MPFSoundAsset", "Resource", preload("classes/mpf_sound.gd"), preload("icons/AudioStreamMP3.svg"))
	add_custom_type("MPFLogger", "Node", preload("classes/mpf_logger.gd"), preload("icons/ConfirmationDialog.svg"))
	add_custom_type("MPFEventHandler", "Control", preload("classes/mpf_event_handler.gd"), preload("icons/RemoteTransform2D.svg"))
	add_custom_type("MPFConditional", "Control", preload("classes/mpf_conditional.gd"), preload("icons/Mesh.svg"))
	add_custom_type("MPFConditionalChildren", "Control", preload("classes/mpf_conditional_children.gd"), preload("icons/MultiMesh.svg"))

	# Create a custom dock for GMC Settings
	gmc_dock = preload("res://addons/mpf-gmc/editor/gmc_panel.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, gmc_dock)
	mpf_dock = preload("res://addons/mpf-gmc/editor/mpf_panel.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, mpf_dock)
	mpf_output = preload("res://addons/mpf-gmc/editor/mpf_output.tscn").instantiate()
	add_control_to_bottom_panel(mpf_output, "MPF Output")
	# Add a custom button for launching with MPF
	# mpf_launch = preload("res://addons/mpf-gmc/editor/mpf_player.tscn").instantiate()
	# add_control_to_container(CONTAINER_TOOLBAR, mpf_launch)
	mpf_debugger = preload("res://addons/mpf-gmc/editor/mpf_debugger.gd").new()
	add_debugger_plugin(mpf_debugger)
	# Add an Export plugin to manage export behavior
	gmc_export = preload("res://addons/mpf-gmc/editor/mpf_gmc_export.gd").new()
	add_export_plugin(gmc_export)

func _ready():
	mpf_debugger.attach_panel(mpf_output)

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
	remove_custom_type("MPFTextInput")

	remove_control_from_docks(gmc_dock)
	gmc_dock.free()
	remove_control_from_docks(mpf_dock)
	mpf_dock.free()
	remove_control_from_bottom_panel(mpf_output)
	mpf_output.free()
	# remove_control_from_container(CONTAINER_TOOLBAR, mpf_launch)
	# mpf_launch.free()
	remove_debugger_plugin(mpf_debugger)
	# mpf_debugger.free()
	remove_export_plugin(gmc_export)
	# gmc_export.free()
