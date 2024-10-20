class_name MPFLogger
extends Node

const LogLevel = preload("res://addons/mpf-gmc/scripts/log.gd").LogLevel

## Logs GMC Node output to the main log.

## If true, nodes attached to this logger will log.
@export var enabled: bool = true
## The log level for the attached nodes to output.
@export var log_level: LogLevel = LogLevel.USE_GLOBAL_LEVEL
## A list of GMC Nodes to log.
## Click 'Add Element' to add slots, and drag nodes to the Assign button to enable logging from them.
@export var loggers: Array[Node]


# This is called on _ready so that child nodes have been instantiated and named.
# Child nodes must define self.log in their _enter_tree() function so that name
# is available. This node must use _ready() because _enter_tree() is sensitive
# to the DOM structure and this node may or may not be before the nodes its trying
# to reference.
func _ready() -> void:
	if not self.loggers or not self.enabled:
		return
	for n in self.loggers:
		if not n or n == null:
			printerr("Found empty array element in MPFLogger %s" % self.name)
		elif n.get("log") is GMCLogger:
			n.log.setLevel(self.log_level)
		else:
			printerr("Node %s does not support GMCLogger. Logging will not be available for this node." % n)

# In case this node is a child of something that wants to show/hide
func show() -> void:
	return

func hide() -> void:
	return
