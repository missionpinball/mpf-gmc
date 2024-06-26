# Copyright 2022 Paradigm Tilt
extends ServicePage

# Initialize in _enter_tree so the children are available
# to be called on _ready()
func _enter_tree():
	List = $MarginContainer/VBoxContainer
	var SettingsSliderScene = preload("res://addons/mpf-gmc/slides/service/Settings_Slider.tscn")
	for bus_name in MPF.media.sound.buses.keys():
		var item = SettingsSliderScene.instantiate()
		# Godot has Master hard-coded to capitalized, but MPF likes lowercase
		if bus_name == "Master":
			bus_name = "master"
		item.name = "%sSlider" % bus_name
		var setting = {
			"label": "%s Volume" % bus_name.capitalize(),
			"variable": "%s_volume" % bus_name,
			"default": 1.0
		}
		item.populate(setting)
		# Update the audio settings in realtime, since there's no "cancel" option
		item.save_on_change = true
		item.persist = true
		self.add_setting(item)
