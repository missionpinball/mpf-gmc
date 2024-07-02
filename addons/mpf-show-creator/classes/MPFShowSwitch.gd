@tool

extends TextureButton
class_name MPFShowSwitch

@export var tags: Array
var server

func _enter_tree():
    self.texture_normal = preload("res://addons/mpf-show-creator/icons/TabBar.svg")

func _ready():
    var parent = self.get_parent()
    self.visible = Engine.is_editor_hint()
    while parent:
        if parent is MPFShowCreator:
            parent.register_switch(self)
        elif parent is MPFMonitor:
            self.visible = true
            server = parent.server
        parent = parent.get_parent()

    self.pressed.connect(self.on_pressed)
    self.toggled.connect(self.on_toggled)
    self.gui_input.connect(self.on_input)

func on_input(event):
    if not event is InputEventMouseButton:
        return
    print("INPUT: %s" % event)
    # Ctrl+click to lock switch on
    var is_pressed = true if event.ctrl_pressed else event.pressed

    server.send_switch(self.name, 1 if is_pressed else 0)

    if is_pressed:
        self.modulate = Color(0.0, 1.0, 0.0)
    else:
        self.modulate = Color(1.0, 1.0, 1.0)


func on_pressed():
    print("Pressed")

func on_toggled(is_toggled):
    print("Toggle state: %s" % is_toggled)
