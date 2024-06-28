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

	var hardware_volumes = MPF.game.settings.values().filter(
		func (s): return s.type == "hw_volume"
	)
	if not hardware_volumes:
		return
	#var separator = HSeparator.new()
	#List.add_child(separator)
	hardware_volumes.sort_custom(func (a, b): return a.priority < b.priority)
	for hw in hardware_volumes:
		var item = SettingsSliderScene.instantiate()
		item.name = "%sSlider" % hw.variable
		var setting = {
			"label": hw.label,
			"variable": hw.variable,
			"default": hw.default
		}
		item.populate(setting)
		item.save_on_change = true
		# Currently only FAST Audio is implemented, so hard code those
		# values because I'm lazy.
		item.min_value = 0
		item.max_value = 63
		item.step = 1
		item.convert_to_percent = false
		self.add_setting(item)
