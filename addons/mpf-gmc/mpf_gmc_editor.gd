@tool
extends EditorPlugin


func _enter_tree():
    # Add the new type with a name, a parent type, a script and an icon.
    add_custom_type("MPFWindow", "Node2D", preload("classes/mpf_window.gd"), null)
    add_custom_type("MPFDisplay", "Node2D", preload("classes/mpf_display.gd"), null)
    add_custom_type("MPFSlide", "Node2D", preload("classes/mpf_slide.gd"), null)
    add_custom_type("MPFVariable", "Label", preload("classes/mpf_variable.gd"), null)

func _exit_tree():
    # Clean-up of the plugin goes here.
    # Always remember to remove it from the engine when deactivated.
    remove_custom_type("MPFDisplay")
    remove_custom_type("MPFWindow")
    remove_custom_type("MPFSlide")
    remove_custom_type("MPFVariable")
