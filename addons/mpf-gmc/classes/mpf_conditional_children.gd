@tool
class_name MPFConditionalChildren
extends MPFConditional


## Override this method to pass in the correct value and set visibility
func show_or_hide():
    var has_visible_children = false
    var fallback_child = null
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
