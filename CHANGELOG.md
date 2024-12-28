# MPF-GMC Changelog

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

