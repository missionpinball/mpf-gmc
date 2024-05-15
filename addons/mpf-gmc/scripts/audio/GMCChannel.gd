@tool
extends AudioStreamPlayer
class_name GMCChannel

# AudioStreamPlayer class has a bus property that is the string name
# of the AudioServer bus. This value is the GMC bus instance.
var _bus: GMCBus

func _init(n: String, b: GMCBus):
	self.name = n
	self._bus = b
