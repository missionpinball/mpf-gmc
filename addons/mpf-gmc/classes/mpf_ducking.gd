@tool
extends Resource
class_name DuckSettings

@export var delay: float
@export var attenuation: float = 0.0
@export var attack: float = 0.5
@export var release: float = 0.5
@export var release_from_start: float
@export var release_point: float = 0.5
var start_time
var release_time: int

func _init(settings: Dictionary = {}):
	for k in settings.keys():
		if self.get(k):
			self[k] = settings[k]

func calculate_release_time(stream: AudioStream = null) -> float:
	if stream:
		self.release_time = Time.get_ticks_msec() + int((stream.get_length() - self.release_point) * 1000)
	elif self.release_from_start:
		self.release_time = Time.get_ticks_msec() + int(release_from_start * 1000)
	else:
		assert(false, "Ducking release requires an AudioStream or release_from_start")
	return self.release_time