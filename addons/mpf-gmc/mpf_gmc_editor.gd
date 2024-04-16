@tool
extends EditorPlugin


func _enter_tree():
    # Add the new type with a name, a parent type, a script and an icon.
    add_custom_type("MPFChildPool", "Node", preload("classes/mpf_child_pool.gd"), null)
    add_custom_type("MPFSceneBase", "Node2D", preload("classes/mpf_scene_base.gd"), null)
    add_custom_type("MPFWidget", "Node2D", preload("classes/mpf_widget.gd"), null)
    add_custom_type("MPFWindow", "Node2D", preload("classes/mpf_window.gd"), null)
    add_custom_type("MPFDisplay", "MPFSceneBase", preload("classes/mpf_display.gd"), null)
    add_custom_type("MPFSlide", "MPFSceneBase", preload("classes/mpf_slide.gd"), null)
    add_custom_type("MPFVariable", "Label", preload("classes/mpf_variable.gd"), null)
    add_custom_type("MPFCarousel", "Node2D", preload("classes/mpf_carousel.gd"), null)
    add_custom_type("MPFVideoPlayer", "VideoStreamPlayer", preload("classes/mpf_video_player.gd"), null)
    add_custom_type("MPFSoundAsset", "Resource", preload("classes/mpf_sound.gd"), null)

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
