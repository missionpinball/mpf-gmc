@tool
class_name MPFConditionalNode
extends MPFConditional

@export var condition_value: String

func show_or_hide():
    self.visible = self.evaluate(self.condition_value)
