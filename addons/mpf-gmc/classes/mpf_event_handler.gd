class_name MPFEventHandler
extends Control
## A node that creates a BCP event handler and calls a method on parent or children.

enum HandlerDirection {
	## The call_method will be called on this node's parent
	PARENT,
	## The call_method will be called on each of this node's children
	CHILDREN,
}

## The name of the MPF event to subscribe to
@export var event_name: String
## The target node(s) to be called when the event occurs
@export var handler_direction: HandlerDirection = HandlerDirection.PARENT
## The name of the method to call
@export var call_method: String

@warning_ignore("shadowed_global_identifier")
var log: GMCLogger


func _enter_tree():
	# Create a log
	self.log = preload("res://addons/mpf-gmc/scripts/log.gd").new("EventHandler<%s>" % self.name)

func _ready() -> void:
	assert(event_name, "MPFEventHandler requires an event_name.")
	assert(call_method, "MPFEventHandler requires a call_method.")
	MPF.server.add_event_handler(event_name, self._on_event)

func _exit_tree():
	MPF.server.remove_event_handler(event_name, self._on_event)

func _on_event(payload: Dictionary) -> void:
	if handler_direction == HandlerDirection.PARENT:
		var parent = self.get_parent()
		if not parent.get(call_method) is Callable:
			self.log.warning("EventHandler parent %s has no method '%s'", [parent, call_method])
		else:
			parent[call_method].call(payload)
	elif handler_direction == HandlerDirection.CHILDREN:
		for c in self.get_children():
			if not c.get(call_method) is Callable:
				self.log.info("EventHandler child %s has no method '%s'", [c, call_method])
			else:
				c[call_method].call(payload)
