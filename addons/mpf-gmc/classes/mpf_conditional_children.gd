class_name MPFConditionalChildren
extends MPFConditional
## A node that conditionally shows or hides its children based on a condition.

func _enter_tree() -> void:
	super()
	for c in self.get_children():
		c.hide()

func _validate_property(property: Dictionary) -> void:
	if property.name in ["condition_type", "condition_value"]:
		property.usage = PROPERTY_USAGE_NO_EDITOR

## Override this method to pass in the correct value and set visibility
func show_or_hide_from_condition() -> void:
	var has_visible_children := false
	var fallback_child: Node = null
	for c in self.get_children():
		# Node names are type StringName, so convert to string
		var child_name =  "%s" % c.name
		if self.evaluate(child_name):
			c.show()
			has_visible_children = true
		elif child_name == "__default__":
			fallback_child = c
		else:
			c.hide()
	if fallback_child:
		if has_visible_children:
			fallback_child.hide()
		else:
			fallback_child.show()
			has_visible_children = true
	self.visible = has_visible_children
