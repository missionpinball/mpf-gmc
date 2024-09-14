class_name MPFSoundAsset
extends Resource

## A custom wrapper for a sound file or AudioStream to apply MPF-related attributes without sound_player parameters.

## A sound file or AudioStream resource to play
@export var stream: AudioStream
## The audio bus on which this sound will be played
@export var bus: String
## The time (in seconds) to fade this sound in over
@export var fade_in: float
## The time (in seconds) to fade this sound out over
@export var fade_out: float
## How many loops to loop this track. -1 means forever.
@export var loops: int
## The timestamp (in seconds) where playback will start
@export var start_at: float
## The maximum amount of time (in seconds) that this sound will be queued in a sequential playback bus.
@export var max_queue_time: float
## Ducking settings for this sound. Can be overridden with sound_player config.
@export var ducking: DuckSettings
## Marker settings for this sound.
@export var markers: Array[SoundMarker]
