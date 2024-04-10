@tool

class_name MPFCarousel
extends Node2D

@export var carousel_name: String

func _ready():
    for c in self.get_children():
        c.hide()
    MPF.server.item_highlighted.connect(self._on_item_highlighted)

func _on_item_highlighted(payload: Dictionary) -> void:
    if payload.carousel != self.carousel_name:
        return
    print("Carousel %s sees item '%s' highlighted!" % [payload.carousel, payload.item])
    for c in self.get_children():
        if c.name == payload.item:
            c.show()
        else:
            c.hide()