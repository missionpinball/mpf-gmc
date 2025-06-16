# Copyright 2021 Paradigm Tilt

extends ServicePage

@export var settingType: String = "standard"

func _ready():
	List = $MarginContainer/VBoxContainer
	var SettingsItemScene = preload("res://addons/mpf-gmc/slides/service/Settings_Item.tscn")
	var settings = MPF.game.settings.values().filter(
		func (s): return s.type == settingType
	)
	settings.sort_custom(self.sort_settings)
	for setting in settings:
		var item = SettingsItemScene.instantiate()
		item.populate(setting)
		self.add_setting(item)

func sort_settings(a: Dictionary, b: Dictionary) -> bool:
	return a.priority < b.priority
