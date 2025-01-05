# Copyright 2022 Paradigm Tilt

extends SettingsItem
class_name Settings_Slider

@export var min_value: int = 0
@export var max_value: int = 100
@export var step: int = 5
@export var save_on_change: bool = false
@export var convert_to_percent: bool = true
var persist = null
# Expose the value of the underlying slider
var value: int:
	get = get_value

func ready() -> void:
	# Shift from a saved float to a displayed int
	if self.convert_to_percent:
		self.selected_value = int(self.selected_value * 100)
	$Setting.text = title
	$HSlider.min_value = min_value
	$HSlider.max_value = max_value
	$HSlider.step = step
	$HSlider.value = selected_value
	$Option.text = "%d" % selected_value
	# Listen for changes in case volumes are linked
	MPF.game.volume.connect(self._on_volume_change)

func select_option(direction: int = 0) -> void:
	var next = (selected_value + ($HSlider.step * direction)) if direction else 0

	if next >= $HSlider.min_value and next <= $HSlider.max_value:
		selected_value = next
		$Option.text = "%d" % selected_value
		$HSlider.value = selected_value
		if save_on_change:
			self.save()

func save() -> void:
	var save_value = self.selected_value
	if self.convert_to_percent:
		# Clamp to 2 decimals by converting to string and back to float
		save_value = float("%0.2f" % (selected_value / 100))
	MPF.server.set_machine_var(variable, save_value, self.persist)

func get_value() -> int:
	return $HSlider.value

func _on_volume_change(bus, new_value, _change) -> void:
	if bus != self.variable:
		return
	if self.convert_to_percent:
		new_value = int(new_value * 100)
	if new_value != selected_value:
		self.selected_value = new_value
		$Option.text = "%d" % selected_value
		$HSlider.value = new_value

func _to_string() -> String:
	return "<SettingsSlider:%s>" % variable
