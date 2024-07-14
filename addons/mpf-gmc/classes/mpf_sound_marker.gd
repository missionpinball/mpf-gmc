extends Resource
class_name SoundMarker


## The playback time will never match the marker time exactly.
const FLOAT_MARGIN = 0.015

@export var time: float
@export var event: String
var _last_marked: float

# TODO: Need to reset on each loop
func reset() -> void:
	self._last_marked = 0.0

func mark(current_time:float) -> int:
	# If this marker has already posted
	if self._last_marked:
		return 0
	# If this marker hasn't been reached yet
	if current_time < self.time:
		return 1
	# If this marker was skipped
	if current_time - self.time > FLOAT_MARGIN:
		return 0
	self._last_marked = current_time
	MPF.server.send_event(self.event)
	MPF.media.sound.marker.emit(self.event)
	return 0

func _to_string() -> String:
	return "Marker<%s:%s>" % [self.time, self.event]