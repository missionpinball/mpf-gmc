@tool
extends Resource
class_name DuckSettings

const merge_props = ["delay", "attenuation", "attack", "release", "release_from_start", "release_point"]

var bus: GMCBus
@export var target_bus: String:
	set = _set_target_bus
@export var delay: float
@export var attenuation: float
@export var attack: float
@export var release: float
@export var release_from_start: float
@export var release_point: float
var start_time
var duration: float
var release_time: int

func _init(settings: Dictionary = {}, fallback: DuckSettings = null):
	# The bus comes as a string, convert it to a GMCBus
	if settings.get("bus"):
		self.bus = MPF.media.sound.get_bus(settings["bus"])
	elif fallback and fallback.bus:
		self.bus = fallback.bus
	for p in merge_props:
		if not self.get(p):
			var val = settings.get(p, fallback.get(p) if fallback else 0.0)
			if val:
				self[p] = val

func calculate_release_time(start_time_msecs: int, stream: AudioStream = null) -> float:
	if stream:
		self.duration = stream.get_length() - self.release_point
	elif self.release_from_start:
		self.duration = release_from_start
	else:
		assert(false, "Ducking release requires an AudioStream or release_from_start")
	self.release_time = start_time_msecs + int(self.duration * 1000)
	return self.release_time

func _set_target_bus(value: String) -> void:
	target_bus = value
	# The saved bus may have been overridden by _init settings
	if not bus:
		bus = MPF.media.sound.get_bus(value)
