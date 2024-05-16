@tool
extends Resource
class_name DuckSettings

var bus: GMCBus
@export var delay: float
@export var attenuation: float = 0.0
@export var attack: float = 0.5
@export var release: float = 0.5
@export var release_from_start: float
@export var release_point: float = 0.0
var start_time
var duration: float
var release_time: int

func _init(settings: Dictionary = {}):
	# The bus comes as a string, convert it to a GMCBus
	if settings["bus"]:
		self.bus = MPF.media.sound.buses[settings["bus"]]
	for k in settings.keys():
		if not self.get(k):
			self[k] = settings[k]


func calculate_release_time(start_time_msecs: int, stream: AudioStream = null) -> float:
	if stream:
		self.duration = stream.get_length() - self.release_point
	elif self.release_from_start:
		self.duration = release_from_start
	else:
		assert(false, "Ducking release requires an AudioStream or release_from_start")
	self.release_time = start_time_msecs + int(self.duration * 1000)
	print("Stream %s is %s long, %ss release means a duration of %s" % [
		stream.resource_name, stream.get_length(), self.release_point, self.duration
	])
	return self.release_time
