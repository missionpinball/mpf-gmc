# Copyright 2021 Paradigm Tilt

extends ServicePage

@export var settingType: String = "standard"

func _ready():
	#var Settings_Item = load("res://service/Settings_Item.tscn")
	var settings = []
	# Godot 3 does not support Array.filter(), so do it manually
	for i in MPF.game.settings.values():
		if i.type == settingType:
			settings.append(i)
	settings.sort_custom(self.sort_settings)
	for setting in settings:
		var item = Settings_Item.new()
		item.initialize(setting)
		self.add_setting(item)

func sort_settings(a: Dictionary, b: Dictionary) -> bool:
	return a.priority < b.priority
