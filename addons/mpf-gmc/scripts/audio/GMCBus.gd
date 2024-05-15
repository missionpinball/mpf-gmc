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

func create_channel(channel_name: String) -> GMCChannel:
	var channel = GMCChannel.new(channel_name, self)
	self.channels.append(channel)
	return channel

func set_type(t: BusType):
	self.type = t
	# Sequential busses get a queue to store pending sounds
	if t == BusType.SEQUENTIAL:
		self.queue = []

static func get_bus_type(bus_string: String) -> BusType:
	return {
		"solo": BusType.SOLO,
		"sequential": BusType.SEQUENTIAL,
		"simultaneous": BusType.SIMULTANEOUS
	}.get(bus_string)