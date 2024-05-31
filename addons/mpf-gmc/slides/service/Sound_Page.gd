# Copyright 2022 Paradigm Tilt
extends ServicePage

func _ready():
  #var Settings_Slider = load("res://service/Settings_Slider.tscn")
  for setting in [
    { "label": "Master Volume", "variable": "master_volume"},
    { "label": "Music Volume", "variable": "music_volume"},
    { "label": "Voice Volume", "variable": "voice_volume"},
    { "label": "Effects Volume", "variable": "sfx_volume"},
  ]:
    var item = Settings_Slider.new()
    setting.default = 100
    item.initialize(setting)
    # Update the audio settings in realtime, since there's no "cancel" option
    item.save_on_change = true
    self.add_setting(item)
