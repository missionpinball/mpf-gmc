@tool
extends RefCounted
class_name GMCBus

enum BusType { SOLO, SEQUENTIAL, SIMULTANEOUS }

var name: String
var channels: Array[GMCChannel] = []
var type: BusType = BusType.SIMULTANEOUS
var queue

func _init(n: String):
	self.name = n

func add_channel(channel: GMCChannel) -> void:
	self.channels.append(channel)

static func get_bus_type(bus_string: String) -> BusType:
	return {
		"solo": BusType.SOLO,
		"sequential": BusType.SEQUENTIAL,
		"simultaneous": BusType.SIMULTANEOUS
	}.get(bus_string)