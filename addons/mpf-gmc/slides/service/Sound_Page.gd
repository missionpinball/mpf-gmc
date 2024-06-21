# Copyright 2022 Paradigm Tilt
extends ServicePage

func _ready():

	List = $MarginContainer/VBoxContainer
	var SettingsSliderScene = preload("res://addons/mpf-gmc/slides/service/Settings_Slider.tscn")
	for setting in [
		{ "label": "Master Volume", "variable": "master_volume"},
		{ "label": "Music Volume", "variable": "music_volume"},
		{ "label": "Voice Volume", "variable": "voice_volume"},
		{ "label": "Effects Volume", "variable": "sfx_volume"},
	]:
		var item = SettingsSliderScene.instantiate()
		setting.default = 100
		item.populate(setting)
		# Update the audio settings in realtime, since there's no "cancel" option
		item.save_on_change = true
		self.add_setting(item)
