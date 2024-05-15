@tool
extends TextureButton

func _enter_tree():
	pressed.connect(self._launch_mpf)
	mouse_entered.connect(self._on_hover)
	mouse_exited.connect(self._off_hover)
	_off_hover()

func _on_hover() -> void:
	modulate.a = 1.0

func _off_hover() -> void:
	modulate.a = 0.75

func _launch_mpf():
	printerr("Launching MPF!!!")
	EditorInterface.play_main_scene()
	MPF.process.launch_mpf()
