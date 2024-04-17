@tool
class_name MPFCarousel
extends Node2D

## Shows and hides child nodes based on the selection of an MPF Carousel mode.
##
## Each child of this Node should have a name matching one of `the selectable_items`
## in the carousel's mode code.
##
## @tutorial: https://missionpinball.org/gmc/reference/mpf-carousel/

## The name of the MPF mode that uses Carousel as its custom mode code.
@export var carousel_name: String

func _ready():
    for c in self.get_children():
        c.hide()
    MPF.server.item_highlighted.connect(self._on_item_highlighted)

func _on_item_highlighted(payload: Dictionary) -> void:
    if payload.carousel != self.carousel_name:
        return
    for c in self.get_children():
        if c.name == payload.item:
            c.show()
        else:
            c.hide()
