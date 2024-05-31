# Copyright 2022 Paradigm Tilt

extends Settings_Item
class_name Settings_Slider

@export var min_value: int = 0
@export var max_value: int = 100
@export var step: int = 5
@export var save_on_change: bool = false
# Expose the value of the underlying slider
var value: float:
	get = get_value

func _ready():
	# _ready() must be defined so parents wait for
	# this node before proceeding with ready()
	pass

func ready() -> void:
	print("Slider has these children:")
	print(self.get_children())
	# Shift from a saved float to a displayed int
	selected_value = int(self.selected_value * 100)
	$Setting.text = title
	$HSlider.value = selected_value
	$HSlider.min_value = min_value
	$HSlider.max_value = max_value
	$HSlider.step = step
	$Option.text = "%d" % selected_value

func select_option(direction: int = 0) -> void:
	var next: float = (selected_value + ($HSlider.step * direction)) if direction else 0

	if next >= $HSlider.min_value and next <= $HSlider.max_value:
		selected_value = next
		$Option.text = "%d" % selected_value
		$HSlider.value = selected_value
		if save_on_change:
			self.save()

func save() -> void:
	var float_val: float = selected_value / 100
	MPF.server.set_machine_var(variable, float_val)

func get_value() -> float:
	return $HSlider.value
