# MPF-GMC Changelog

## 0.1.5
*24 July 2025*

### New Features

* MPF Version Check to ensure cross-compatibility between MPF and GMC versions

### Improvements

* Reset anchors and offsets on slide and widget nodes for better dynamic layouts
* Overlay slide layout to full rect
* Substantially more logging on sound playback

### Bug Fixes

* Fixed a case mismatch on Settings Item
* Fix a crash if no gmc.cfg file is present

## 0.1.4
*10 April 2025*

### New Features

* New `MPFConditional` variable type `ACTIVE_SLIDE` to match conditions based on the active slide (most likely the variable name "name" to match the name of the active slide). Will automatically re-evaluate when the slides change.

* New `MPFSlide` property `mask_from_active` to prevent designated slides from being considered "active" (will not post *slide_(name)_active* events or match against `MPFConditional.ACTIVE_SLIDE` conditions).

* New slide_player / widget_player `action: animation` to play an animation from a triggering event. Include `animation: <animation_name>` in the player config to specify which animation to play. The corresponding MPFSlide/MPFWidget must have an `animation_player` node assigned in the Inspector panel.

```
slide_player:
  item_highlighted:
    carousel_slide:
	  action: animation
	  animation: item_highlight_anim
```

* New _gmc.cfg_ section `[window]` with support for `scale: (float)` and `size: (Vector2)` properties. Especially useful when used in _gmc.local.cfg_ for designating a downsized window on a development computer but full-size (multi-monitor-spanning) displays on the physical machine.

* Default slides for Tilt mode now included with GMC.

### Improvements

* `MPFConditional` with min/max players will auto-update when player count changes
* BCP Signals now use `Callable.emit.call_deferred()` instead of `call_deferred("emit_signal", "Callable")`, per Godot guidance
* Better handling of `ps` command when spawning MPF process (Mac and Linux)

### Bug Fixes

* Fix WAV audio files not looping properly when not explicitly re-imported with loop metadata
* Fix `MPFConditional` not checking min/max players when conditional value changes
* Fix `MPFConditional` always evaluating false if the comparison value is falsey (e.g. `0`)
* Fix `MPFTextInput` not respecting `max_length` parameter during text input (e.g. high score entry)

### Other Changes

* The special slide target `_overlay` now has an explicit z-index of 4000 to ensure it is positioned above other slides, even if they have a z-index defined (e.g. UI slides rendered on top of the "active" slide). The maximum z-index is 4096 so other slides can still supersede the overlay slide if desired.

## 0.1.3
*24 January 2025*

### BREAKING CHANGES

* A few GMC nodes derived from `Node2D` have been converted to derive from `Control`. All scenes that use the impacted nodes must be manually updated to re-define the GMC nodes. Instructions and questions can be found on the [MPF Google Forum](https://groups.google.com/g/mpf-users/c/eogaMj_sVNk). The impacted nodes are:
  * `MPFCarousel`
  * `MPFChildPool`
  * `MPFConditional`
  * `MPFConditionalChildren`
  * `MPFEventHandler`

### New Features

* New method `MPF.util.mins_secs()` to convert a seconds integer to formatted clock time (e.g. `73` -> `"1:13"`)
* Keyboard events in *gmc.cfg* now support kwargs
* Optional method `MPF.ignore_input()` to not block GUI input events (for GMC Toolkit)

### Improvements

* `MPFVariable` will now subscribe and update machine variables in realtime
* Service mode improved handling of inputs and keyboard emulation

### Bug Fixes

* Fix `MPFVariable.initialize_empty` not properly behaving
* Fix `GMCBUS.BusType.SOLO` not resuming faded out music during replacement
* Fix `MPFConditional` crashing on player 4
* Fix `MPFVariable` crashing when using template strings on numbers
* Fix `MPF.game.num_players` not resetting after each game
* Fix `[filter]` config option not rendering shader filters
* Fix crash on stopping tweens calling `stop_all()` instead of `stop()`
* Fix Service mode crashing if a switch has no `number:` defined
* Fix GMC panel options showing toggles enabled but being undefined (disabled)
* Catch possible race condition on BCP client shutdown causing a crash
* Catch an error on exiting Godot Editor with RefCounted objects in memory

## 0.1.2
*27 December 2024*

### Features

* Support for RGB DMD displays with new class `MPFDMDDisplay`
* Specify a BCP port with the *gmc.cfg* option `bcp_port=XXXX`
* BCPServer method `send_bytes()` for byte transmission

### Improvements

* Don't auto-pause video previews in editor
* Renamed "Autoloads" to "Globals" in docs per Godot 4.3 change
* Removed WIP show creator addon from repo
* Exclude root files from ZIP bundle to avoid file conflicts when installing from Asset Library
* Added this CHANGELOG file

### Bug Fixes

* Fix `MPFConditional` ref to machine variables
* Handle MPF inconsistency in `num` vs `player_num` kwarg in *player_added* event

