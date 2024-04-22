# MPF-GMC: Godot Media Controller for the Mission Pinball Framework

![Godot BCP Logo](https://github.com/missionpinball/godot-bcp-server/blob/main/icon.png?raw=true)

The Godot MC (GMC) is a media controller for rendering screen and audio content in pinball games created using the [Mission Pinball Framework](https://www.missionpinball.org) (MPF).

It is built on top of the [Godot BCP Server](https://github.com/missionpinball/godot-bcp-server) and will replace the old Kivy-based [MPF Media Controller](https://github.com/missionpinball/mpf-mc)

With the Godot MC, pinball creators using MPF can choose Godot as their display engine and drive all screen slides, videos, animations, and sounds via a Godot project.

> [!WARNING]
> Godot MC is in early development. While all core functionality is available and games can be run, implementations and usage may change frequently. We hope you'll give it a try, but breaking changes may occur.

## Features
* Direct socket connection between MPF and Godot for high-speed synchronization
* Fully extensible base classes allow customization and overrides
* Direct access to player variables, machine variables, and settings
* Built-in signals for core events, extensible to add any signals you need
* Easily subscribe to MPF events and send events to MPF
* Support for keyboard input bindings to aid in development

# Installation & Documentation

Full installation guides and documentation are available at https://missionpinball.org/gmc/

# Contributing

User contributions are welcome!

https://github.com/missionpinball/mpf-gmc

For questions and support, please open an issue in the above GitHub repository or visit the MPF forums at https://groups.google.com/g/mpf-users

## License
[MIT](https://choosealicense.com/licenses/mit/)