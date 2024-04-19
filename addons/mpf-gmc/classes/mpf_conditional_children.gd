@tool
class_name MPFConditionalChildren
extends MPFConditional


## Override this method to pass in the correct value and set visibility
func show_or_hide():
    var has_visible_children = false
    for c in self.get_children():
        # Node names are type StringName, so convert to string
        if self.evaluate("%s" % c.name):
            c.show()
            has_visible_children = true
        else:
            c.hide()
    self.visible = has_visible_children
