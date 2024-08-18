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
@warning_ignore("shadowed_global_identifier")
var log: GMCLogger


func _enter_tree():
	# Create a log
	self.log = preload("res://addons/mpf-gmc/scripts/log.gd").new("Carousel<%s>" % self.name)

func _ready():
	for c in self.get_children():
		c.hide()
	if not carousel_name:
		carousel_name = self.name
	MPF.server.item_highlighted.connect(self._on_item_highlighted)

func _on_item_highlighted(payload: Dictionary) -> void:
	if payload.get("carousel") != self.carousel_name:
		return
	self.log.debug("Carousel looking for child matching name '%s'", payload.item)
	for c in self.get_children():
		if c.name == payload.item:
			c.show()
		else:
			c.hide()
