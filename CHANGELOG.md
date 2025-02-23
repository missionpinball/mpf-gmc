# MPF-GMC Changelog

## 0.1.4
*Unreleased, available on `main` branch*

### Improvements

* `MPFConditional` with min/max players will auto-update when player count changes

### Bug Fixes

* Fix WAV files not looping properly without loop metadata via re-import
* Fix `MPFConditional` not checking min/max players when conditional value changes

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

