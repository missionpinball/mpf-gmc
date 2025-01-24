# MPF-GMC Changelog

## 0.1.3
*Upcoming, on main branch as of 10 Jan 2025*

### BREAKING CHANGES

* A few GMC nodes derived from `Node2D` have been converted to derive from `Control`. All scenes that use the impacted nodes must be manually updated to re-define the GMC nodes. Instructions and questions can be found on the [MPF Google Forum](https://groups.google.com/g/mpf-users/c/eogaMj_sVNk). The impacted nodes are:
* * `MPFCarousel`
* * `MPFChildPool`
* * `MPFConditional`
* * `MPFConditionalChildren`
* * `MPFEventHandler`

### Improvements

* `MPFVariable` will now subscribe and update machine variables in realtime
* Service mode improved handling of inputs and keyboard emulation
* Keyboard events in *gmc.cfg* now support kwargs
* New method `MPF.util.mins_secs()` to convert a seconds integer to formatted clock time
* Optional method to allow GUI input events (for GMC Toolkit)

### Bug Fixes

* Fix `MPFVariable.initialize_empty` not properly behaving
* Fix music bus not resuming faded out music during replacement
* Fix GMC panel options showing enabled but being undefined (disabled)
* Fix `MPFConditional` crashing on player 4
* Fix `MPFVariable` crashing when using template strings on numbers
* Fix Service mode crashing if a switch has no `number:` defined
* Fix `MPF.game.num_players` not resetting after each game
* Fix `[filter]` config option not rendering shader filters
* Catch possible race condition on BCP client shutdown causing a crash

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

