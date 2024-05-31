# Copyright 2022 Paradigm Tilt

tool
extends Settings_Item
class_name Settings_Slider

export (int) var min_value = 0
export (int) var max_value = 100
export (int) var step = 5
export (bool) var save_on_change = false
# Expose the value of the underlying slider
var value: float setget , get_value

func ready() -> void:
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
  Server.set_machine_var(variable, float_val)

func get_value() -> float:
  return $HSlider.value
